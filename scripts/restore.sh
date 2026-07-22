#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Script Variables ---
SERVER=""
USERNAME=""

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 <SERVER_IP_OR_HOSTNAME> <USERNAME> [BACKUP_FILE]${NC}"
    echo -e "${YELLOW}  SERVER_IP_OR_HOSTNAME: The IP address or hostname of the production server.${NC}"
    echo -e "${YELLOW}  USERNAME: The SSH username for the production server.${NC}"
    echo -e "${YELLOW}  BACKUP_FILE (optional): The full path to the .tar.gz backup file to restore.\n${NC}"
    echo -e "${YELLOW}  If not provided, the latest backup in ${LOCAL_BACKUPS_DIR} will be used.${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 2 ]; then
    usage
fi

SERVER="$1"
USERNAME="$2"
SSH_TARGET="${USERNAME}@${SERVER}"

BACKUP_FILE="$3"

if [ -z "$BACKUP_FILE" ]; then
    # Get the latest backup file if not specified
    BACKUP_FILE=$(ls -t "${LOCAL_BACKUPS_DIR}"/${SAVAREZ_THEME_APP_NAME}_*.tar.gz 2>/dev/null | head -n 1)
    if [ -z "$BACKUP_FILE" ]; then
        error_exit "No backup files found in ${LOCAL_BACKUPS_DIR}. Please specify a backup file or create one first."
    fi
    log INFO "Using latest backup file: $(basename "${BACKUP_FILE}")"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    error_exit "Backup file not found: ${BACKUP_FILE}"
fi

log INFO "Starting restore of ${SAVAREZ_THEME_APP_NAME} on ${SERVER} from ${BACKUP_FILE}...
"

REMOTE_TEMP_TAR="/tmp/$(basename "${BACKUP_FILE}")"

# 1. Upload the backup tarball to the remote server
log INFO "1. Uploading backup tarball to remote server: ${REMOTE_TEMP_TAR}"
scp "${BACKUP_FILE}" "${SSH_TARGET}:${REMOTE_TEMP_TAR}"
if [ $? -ne 0 ]; then
    error_exit "SCP failed to upload backup tarball to remote."
fi
log SUCCESS "Backup tarball uploaded."

# 2. Disable Nextcloud app, remove current app, and extract backup
log INFO "2. Disabling Nextcloud app, removing current app, and extracting backup..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:disable ${SAVAREZ_THEME_APP_NAME} > /dev/null || true"
run_remote_cmd "$SERVER" "$USERNAME" "sudo rm -rf ${NC_SAVAREZ_THEME_PATH}"
run_remote_cmd "$SERVER" "$USERNAME" "sudo tar -xzf ${REMOTE_TEMP_TAR} -C $(dirname ${NC_SAVAREZ_THEME_PATH})"
log SUCCESS "Previous app removed and backup extracted."

# 3. Fix ownership and permissions
log INFO "3. Fixing ownership and permissions..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo chown -R ${WEB_USER}:${WEB_GROUP} ${NC_SAVAREZ_THEME_PATH}"
run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type d -exec chmod 755 {} \;"
run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type f -exec chmod 644 {} \;"
log SUCCESS "Ownership and permissions fixed."

# 4. Clear Nextcloud cache and enable app
log INFO "4. Clearing Nextcloud cache and enabling app..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:enable ${SAVAREZ_THEME_APP_NAME}"
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ cache:clear"
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ config:system:set asset-pipeline.enabled --value=false --type=boolean || true"
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ config:system:set asset-pipeline.enabled --value=true --type=boolean || true"
log SUCCESS "Nextcloud cache cleared and app re-enabled."

# 5. Restart Apache
log INFO "5. Restarting web service (${WEB_SERVICE_NAME})..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo systemctl restart ${WEB_SERVICE_NAME}"
log SUCCESS "Web service restarted."

# 6. Clean up temporary tarball on the remote server
log INFO "6. Cleaning up temporary tarball on remote server..."
run_remote_cmd "$SERVER" "$USERNAME" "rm ${REMOTE_TEMP_TAR}"
log SUCCESS "Temporary tarball cleaned up on remote server."

log SUCCESS "Restore of ${SAVAREZ_THEME_APP_NAME} completed successfully!"
