#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Script Variables ---
SERVER=""
USERNAME=""
PASSWORD=""

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 <SERVER_IP_OR_HOSTNAME> <USERNAME>${NC}"
    echo -e "${YELLOW}  SERVER_IP_OR_HOSTNAME: The IP address or hostname of the production server.${NC}"
    echo -e "${YELLOW}  USERNAME: The SSH username for the production server.${NC}"
    echo -e "${YELLOW}  Environment variable PASSWORD can be used, or you will be prompted.${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 2 ]; then
    usage
fi

SERVER="$1"
USERNAME="$2"

# Get password securely
if [ -z "$PASSWORD" ]; then
    if [ -z "${NC_PROD_PASSWORD}" ]; then # Check if PASSWORD is set in config.sh (not recommended for production)
        echo -n "Enter SSH/Nextcloud password for ${USERNAME}@${SERVER}: "
        read -s PASSWORD
        echo
    else
        PASSWORD="${NC_PROD_PASSWORD}"
    fi
fi

SSH_TARGET="${USERNAME}@${SERVER}"
SNAPSHOT_TIMESTAMP=$(get_timestamp)
METADATA_FILE="${LOCAL_SNAPSHOTS_DIR}/metadata.json"

log INFO "Fetching DOM snapshots from ${SSH_TARGET}..."

# Update metadata
log INFO "Updating snapshot metadata..."
METADATA_JSON="$(cat "${METADATA_FILE}" 2>/dev/null || echo '{\"snapshots\":[]}')"
NEW_METADATA_ENTRY='{"timestamp":"'"${SNAPSHOT_TIMESTAMP}"'", "server":"'"${SERVER}"'", "username":"'"${USERNAME}"'"}'
METADATA_JSON=$(echo "$METADATA_JSON" | jq --argjson newEntry "$NEW_METADATA_ENTRY" '.snapshots += [$newEntry]')
echo "$METADATA_JSON" | jq . > "${METADATA_FILE}"
log SUCCESS "Metadata updated: ${METADATA_FILE}"

# --- Remote Login and Cookie Handling ---
log INFO "Attempting remote Nextcloud login to obtain cookies..."
# Use a unique temporary cookie file for each run
REMOTE_COOKIE_JAR="/tmp/nc_cookies_${SNAPSHOT_TIMESTAMP}.txt"
LOGIN_COMMAND="curl -s -c ${REMOTE_COOKIE_JAR} -b ${REMOTE_COOKIE_JAR} -L 'http://localhost/login' -d 'user=${USERNAME}&password=${PASSWORD}' -o /dev/null"
run_remote_cmd "$SERVER" "$USERNAME" "$LOGIN_COMMAND"

# --- Fetching Pages ---

# Login Page (no cookie needed for this one)
log INFO "  Fetching login page..."
run_remote_cmd "$SERVER" "$USERNAME" "curl -s http://localhost/login" > "${LOCAL_SNAPSHOTS_DIR}/login/login_${SNAPSHOT_TIMESTAMP}.html"
log SUCCESS "  Snapshot saved: ${LOCAL_SNAPSHOTS_DIR}/login/login_${SNAPSHOT_TIMESTAMP}.html"

# Dashboard Page
log INFO "  Fetching dashboard page..."
run_remote_cmd "$SERVER" "$USERNAME" "curl -s -b ${REMOTE_COOKIE_JAR} http://localhost/index.php/apps/dashboard" > "${LOCAL_SNAPSHOTS_DIR}/dashboard/dashboard_${SNAPSHOT_TIMESTAMP}.html"
log SUCCESS "  Snapshot saved: ${LOCAL_SNAPSHOTS_DIR}/dashboard/dashboard_${SNAPSHOT_TIMESTAMP}.html"

# Files Page
log INFO "  Fetching files page..."
run_remote_cmd "$SERVER" "$USERNAME" "curl -s -b ${REMOTE_COOKIE_JAR} http://localhost/index.php/apps/files" > "${LOCAL_SNAPSHOTS_DIR}/files/files_${SNAPSHOT_TIMESTAMP}.html"
log SUCCESS "  Snapshot saved: ${LOCAL_SNAPSHOTS_DIR}/files/files_${SNAPSHOT_TIMESTAMP}.html"

# Settings Page
log INFO "  Fetching settings page..."
run_remote_cmd "$SERVER" "$USERNAME" "curl -s -b ${REMOTE_COOKIE_JAR} http://localhost/index.php/settings/user" > "${LOCAL_SNAPSHOTS_DIR}/settings/settings_${SNAPSHOT_TIMESTAMP}.html"
log SUCCESS "  Snapshot saved: ${LOCAL_SNAPSHOTS_DIR}/settings/settings_${SNAPSHOT_TIMESTAMP}.html"

# Activity Page
log INFO "  Fetching activity page..."
run_remote_cmd "$SERVER" "$USERNAME" "curl -s -b ${REMOTE_COOKIE_JAR} http://localhost/index.php/apps/activity" > "${LOCAL_SNAPSHOTS_DIR}/activity/activity_${SNAPSHOT_TIMESTAMP}.html"
log SUCCESS "  Snapshot saved: ${LOCAL_SNAPSHOTS_DIR}/activity/activity_${SNAPSHOT_TIMESTAMP}.html"

# Clean up remote cookie file
run_remote_cmd "$SERVER" "$USERNAME" "rm ${REMOTE_COOKIE_JAR}"
log SUCCESS "DOM snapshot fetching completed. Remote cookies cleaned up."
