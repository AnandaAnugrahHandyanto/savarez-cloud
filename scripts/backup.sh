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

log INFO "Starting backup of ${SAVAREZ_THEME_APP_NAME} from ${SERVER} to local...
"

# Create local backup directory if it doesn't exist
mkdir -p "${LOCAL_BACKUPS_DIR}"

TIMESTAMP=$(get_timestamp)
BACKUP_NAME="${SAVAREZ_THEME_APP_NAME}_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${LOCAL_BACKUPS_DIR}/${BACKUP_NAME}"
REMOTE_TEMP_TAR="/tmp/${BACKUP_NAME}"

# 1. Create tarball of the app on the remote server
log INFO "1. Creating tarball of remote app ${NC_SAVAREZ_THEME_PATH} on ${SERVER}..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo tar -czf ${REMOTE_TEMP_TAR} -C $(dirname ${NC_SAVAREZ_THEME_PATH}) $(basename ${NC_SAVAREZ_THEME_PATH})"
log SUCCESS "Tarball created on remote server: ${REMOTE_TEMP_TAR}"

# 2. Copy the tarball to local backups directory
log INFO "2. Copying tarball from remote to local: ${BACKUP_PATH}"
scp "${SSH_TARGET}:${REMOTE_TEMP_TAR}" "${BACKUP_PATH}"
if [ $? -ne 0 ]; then
    error_exit "SCP failed to copy tarball from remote to local."
fi
log SUCCESS "Backup saved locally: ${BACKUP_PATH}"

# 3. Clean up the temporary tarball on the remote server
log INFO "3. Cleaning up temporary tarball on remote server..."
run_remote_cmd "$SERVER" "$USERNAME" "rm ${REMOTE_TEMP_TAR}"
log SUCCESS "Temporary tarball cleaned up on remote server."

log SUCCESS "Backup of ${SAVAREZ_THEME_APP_NAME} completed successfully!"
