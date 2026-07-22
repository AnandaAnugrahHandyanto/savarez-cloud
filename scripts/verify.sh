#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Script Variables ---
SERVER=""
USERNAME=""

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 <SERVER_IP_OR_HOSTNAME> <USERNAME>${NC}"
    echo -e "${YELLOW}  SERVER_IP_OR_HOSTNAME: The IP address or hostname of the production server.${NC}"
    echo -e "${YELLOW}  USERNAME: The SSH username for the production server.${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 2 ]; then
    usage
fi

SERVER="$1"
USERNAME="$2"
SSH_TARGET="${USERNAME}@${SERVER}"

log INFO "Starting comprehensive verification of ${SAVAREZ_THEME_APP_NAME} on ${SERVER}...
"

# Check dependencies (ssh, curl, jq)
check_dependencies "ssh" "curl" "jq"

# --- Verification Steps ---
VERIFY_STATUS=0 # 0 for success, 1 for failure

# Helper function to run remote command and check status, setting VERIFY_STATUS on failure
check_remote_cmd() {
    local DESCRIPTION="$1"
    local COMMAND="$2"
    local EXPECT_SUCCESS="$3"
    local RESULT

    log INFO "- ${DESCRIPTION}"
    RESULT=$(ssh "$SSH_TARGET" "$COMMAND" 2>&1)
    local SSH_EXIT_CODE=$?

    if [ "$EXPECT_SUCCESS" == "true" ]; then
        if [ $SSH_EXIT_CODE -eq 0 ]; then
            log SUCCESS "  -> OK: ${DESCRIPTION}"
        else
            log ERROR "  -> FAILED: ${DESCRIPTION}. Error: ${RESULT}"
            VERIFY_STATUS=1
        fi
    else # Expect failure
        if [ $SSH_EXIT_CODE -ne 0 ]; then
            log SUCCESS "  -> OK: ${DESCRIPTION} (expected failure)."
        else
            log ERROR "  -> FAILED: ${DESCRIPTION} (expected failure, but command succeeded). Output: ${RESULT}"
            VERIFY_STATUS=1
        fi
    fi
}

# 1. Check if app directory exists on production
check_remote_cmd "App directory exists: ${NC_SAVAREZ_THEME_PATH}" "[ -d ${NC_SAVAREZ_THEME_PATH} ]" "true"

# 2. Check Nextcloud reachability (basic check via occ status)
check_remote_cmd "Nextcloud is reachable" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ status > /dev/null 2>&1" "true"

# 3. Check info.xml validity (remote check)
log INFO "- Checking info.xml validity..."
XML_CHECK=$(ssh "$SSH_TARGET" "xmllint --noout ${NC_SAVAREZ_THEME_PATH}/appinfo/info.xml 2>/dev/null; echo \"$?\"")
if [ "$XML_CHECK" -eq 0 ]; then
    log SUCCESS "  -> OK: info.xml is valid."
else
    log ERROR "  -> FAILED: info.xml is invalid. Error code: ${XML_CHECK}"
    VERIFY_STATUS=1
fi

# 4. Check if app is active via OCC
log INFO "- Checking if ${SAVAREZ_THEME_APP_NAME} app is active via OCC..."
APP_STATUS=$(ssh "$SSH_TARGET" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:status ${SAVAREZ_THEME_APP_NAME} | grep -E \"enabled:\" | awk '{print $2}'")
if [ "$APP_STATUS" == "yes" ]; then
    log SUCCESS "  -> OK: App ${SAVAREZ_THEME_APP_NAME} is active."
else
    log ERROR "  -> FAILED: App ${SAVAREZ_THEME_APP_NAME} is NOT active. Status: ${APP_STATUS}"
    VERIFY_STATUS=1
fi

# 5. Check login page HTTP 200 (external check)
log INFO "- Checking login page HTTP 200..."
LOGIN_URL="http://${SERVER}/login"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$LOGIN_URL")
if [ "$HTTP_STATUS" -eq 200 ]; then
    log SUCCESS "  -> OK: Login page (${LOGIN_URL}) returned HTTP 200."
else
    log ERROR "  -> FAILED: Login page (${LOGIN_URL}) returned HTTP ${HTTP_STATUS}."
    VERIFY_STATUS=1
fi

# 6. Check main CSS endpoint HTTP 200
log INFO "- Verifying main CSS endpoint (HTTP 200)..."
MAIN_CSS_URL="http://${SERVER}/apps/${SAVAREZ_THEME_APP_NAME}/css/style.css"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$MAIN_CSS_URL")
if [ "$HTTP_STATUS" -eq 200 ]; then
    log SUCCESS "  -> OK: Main CSS endpoint (${MAIN_CSS_URL}) returned HTTP 200."
else
    log ERROR "  -> FAILED: Main CSS endpoint (${MAIN_CSS_URL}) returned HTTP ${HTTP_STATUS}."
    VERIFY_STATUS=1
fi

# 7. Check if Savarez stylesheet appears in HTML of a page (e.g., login page HTML)
log INFO "- Checking if Savarez stylesheet is linked in login page HTML..."
LOGIN_PAGE_HTML=$(curl -s "$LOGIN_URL")
if echo "$LOGIN_PAGE_HTML" | grep -q "${SAVAREZ_THEME_APP_NAME}/css/style.css"; then
    log SUCCESS "  -> OK: Savarez stylesheet link found in login page HTML."
else
    log ERROR "  -> FAILED: Savarez stylesheet link NOT found in login page HTML."
    VERIFY_STATUS=1
fi

# 8. Check CSS file size (local vs remote)
log INFO "- Checking main CSS file size (local vs remote)..."
LOCAL_CSS_PATH="${LOCAL_APP_PATH}/css/style.css"
LOCAL_CSS_SIZE=$(wc -c < "$LOCAL_CSS_PATH" 2>/dev/null || echo 0)
if [ "$LOCAL_CSS_SIZE" -eq 0 ]; then
    log WARN "  -> WARN: Local main CSS file (${LOCAL_CSS_PATH}) not found or empty. Skipping size comparison."
else
    REMOTE_CSS_SIZE=$(ssh "$SSH_TARGET" "wc -c < ${NC_SAVAREZ_THEME_PATH}/css/style.css 2>/dev/null || echo 0")
    if [ "$REMOTE_CSS_SIZE" -eq "$LOCAL_CSS_SIZE" ]; then
        log SUCCESS "  -> OK: Remote CSS size (${REMOTE_CSS_SIZE} bytes) matches local CSS size."
    else
        log ERROR "  -> FAILED: Remote CSS size (${REMOTE_CSS_SIZE} bytes) does NOT match local CSS size (${LOCAL_CSS_SIZE} bytes)."
        VERIFY_STATUS=1
    fi
fi

# 9. Verify main JS endpoint HTTP 200 (if applicable, assuming a main JS file)
log INFO "- Verifying main JS endpoint (HTTP 200)..."
MAIN_JS_URL="http://${SERVER}/apps/${SAVAREZ_THEME_APP_NAME}/js/main.js"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$MAIN_JS_URL")
if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 404 ]; then # 404 is acceptable if JS not present by default
    log SUCCESS "  -> OK: Main JS endpoint (${MAIN_JS_URL}) returned HTTP ${HTTP_STATUS} (200 or 404 acceptable)."
else
    log ERROR "  -> FAILED: Main JS endpoint (${MAIN_JS_URL}) returned unexpected HTTP ${HTTP_STATUS}."
    VERIFY_STATUS=1
fi

# 10. Check permissions for app directory (basic)
log INFO "- Checking permissions for app directory..."
PERMS=$(ssh "$SSH_TARGET" "stat -c '%a %U %G' ${NC_SAVAREZ_THEME_PATH}" 2>/dev/null)
if [ $? -eq 0 ]; then
    OWNER=$(echo "$PERMS" | awk '{print $2}')
    GROUP=$(echo "$PERMS" | awk '{print $3}')
    if [ "$OWNER" == "${WEB_USER}" ] && [ "$GROUP" == "${WEB_GROUP}" ]; then
        log SUCCESS "  -> OK: App directory ownership is correct (${WEB_USER}:${WEB_GROUP})."
    else
        log ERROR "  -> FAILED: App directory ownership is incorrect. Expected ${WEB_USER}:${WEB_GROUP}, got ${OWNER}:${GROUP}."
        VERIFY_STATUS=1
    fi
else
    log ERROR "  -> FAILED: Could not check ownership for ${NC_SAVAREZ_THEME_PATH}. App directory might not exist."
    VERIFY_STATUS=1
fi

# --- Final Report ---
log INFO "
--- Verification Summary ---"
if [ "$VERIFY_STATUS" -eq 0 ]; then
    log SUCCESS "All critical checks passed. ${SAVAREZ_THEME_APP_NAME} appears to be healthy."
else
    log ERROR "Some verification checks FAILED. Please review the logs above."
fi

exit $VERIFY_STATUS
