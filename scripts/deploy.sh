#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Script Variables ---
DRY_RUN=false
NO_RESTART=false
SKIP_BACKUP=false

# --- Global variables for rollback ---
BACKUP_RESTORE_PATH=""
DEPLOY_STATUS=0 # 0 for success, 1 for failure

# --- Trap for cleanup and rollback on exit ---
cleanup_and_rollback() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log ERROR "Deployment failed (exit code: ${exit_code}). Initiating rollback..."
        if [ -n "$BACKUP_RESTORE_PATH" ]; then
            log INFO "Restoring from backup: ${BACKUP_RESTORE_PATH}"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo rm -rf ${NC_SAVAREZ_THEME_PATH}"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo cp -r ${BACKUP_RESTORE_PATH} ${NC_SAVAREZ_THEME_PATH}"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo chown -R ${WEB_USER}:${WEB_GROUP} ${NC_SAVAREZ_THEME_PATH}"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type d -exec chmod 755 {} \;"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type f -exec chmod 644 {} \;"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:enable ${SAVAREZ_THEME_APP_NAME}"
            run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ cache:clear"
            if ! $NO_RESTART; then
                run_remote_cmd "$SERVER" "$USERNAME" "sudo systemctl restart ${WEB_SERVICE_NAME}"
            fi
            log SUCCESS "Rollback completed successfully from ${BACKUP_RESTORE_PATH}."
        else
            log WARN "No backup path available, cannot perform automatic rollback."
        fi
        DEPLOY_STATUS=1
    fi

    # Final Summary
    log INFO "
--- Deployment Summary ---"
    if [ $DEPLOY_STATUS -eq 0 ]; then
        log SUCCESS "${SAVAREZ_THEME_APP_NAME} deployed successfully to ${SERVER}."
    else
        log ERROR "${SAVAREZ_THEME_APP_NAME} deployment FAILED on ${SERVER}. Check logs for details."
    fi
    exit $DEPLOY_STATUS
}

trap cleanup_and_rollback EXIT

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 <SERVER_IP_OR_HOSTNAME> <USERNAME> [--dry-run] [--no-restart] [--skip-backup]${NC}"
    echo -e "${YELLOW}  SERVER_IP_OR_HOSTNAME: The IP address or hostname of the production server.${NC}"
    echo -e "${YELLOW}  USERNAME: The SSH username for the production server.${NC}"
    echo -e "${YELLOW}  --dry-run: Simulate the deployment without making any changes.${NC}"
    echo -e "${YELLOW}  --no-restart: Skip the web server restart step.${NC}"
    echo -e "${YELLOW}  --skip-backup: Skip the production app backup step.${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 2 ]; then
    usage
fi

SERVER="$1"
USERNAME="$2"
shift 2

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --dry-run)
            DRY_RUN=true
            log INFO "Dry run mode activated. No changes will be made."
            shift
            ;;
        --no-restart)
            NO_RESTART=true
            log INFO "Web server restart will be skipped."
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            log INFO "Production app backup will be skipped."
            shift
            ;;
        *)
            log WARN "Unknown option: $1"
            usage
            ;;
    esac
done

# --- Main Deployment Pipeline ---
log INFO "Starting deployment of ${SAVAREZ_THEME_APP_NAME} to ${SERVER} as ${USERNAME}...
"

# Check dependencies (ssh, scp)
check_dependencies "ssh" "scp"

# 1. Validate source
log INFO "1. Validating local source directory: ${LOCAL_APP_PATH}"
if [ ! -d "${LOCAL_APP_PATH}" ]; then
    error_exit "Local app source directory not found: ${LOCAL_APP_PATH}"
fi
log SUCCESS "Source directory validated."

# 2. Backup production app (unless skipped or dry run)
if ! $SKIP_BACKUP && ! $DRY_RUN; then
    log INFO "2. Backing up existing production app..."
    TIMESTAMP=$(get_timestamp)
    REMOTE_BACKUP_PATH="${NC_APP_DIR}/apps/${SAVAREZ_THEME_APP_NAME}_backups/${SAVAREZ_THEME_APP_NAME}_${TIMESTAMP}"
    run_remote_cmd "$SERVER" "$USERNAME" "mkdir -p ${NC_APP_DIR}/apps/${SAVAREZ_THEME_APP_NAME}_backups"
    run_remote_cmd "$SERVER" "$USERNAME" "[ -d ${NC_SAVAREZ_THEME_PATH} ] && cp -r ${NC_SAVAREZ_THEME_PATH} ${REMOTE_BACKUP_PATH} || echo \"No existing app to backup\""
    BACKUP_RESTORE_PATH="${REMOTE_BACKUP_PATH}" # Set for potential rollback
    log SUCCESS "Production app backed up to ${BACKUP_RESTORE_PATH}"
elif $SKIP_BACKUP; then
    log WARN "2. Skipping production app backup as requested."
else
    log INFO "2. Skipping production app backup in dry-run mode."
fi

if $DRY_RUN; then
    log INFO "Dry run complete. No changes were made."
    DEPLOY_STATUS=0
    exit 0
fi

# 3. Copy app/
log INFO "3. Copying local app to production server..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo rm -rf ${NC_SAVAREZ_THEME_PATH} && sudo mkdir -p ${NC_SAVAREZ_THEME_PATH}"
copy_remote_file "${LOCAL_APP_PATH}" "${NC_APP_DIR}/apps/" "$SERVER" "$USERNAME"
log SUCCESS "App copied to ${NC_SAVAREZ_THEME_PATH}"

# 4. Fix ownership
log INFO "4. Fixing ownership for ${NC_SAVAREZ_THEME_PATH}..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo chown -R ${WEB_USER}:${WEB_GROUP} ${NC_SAVAREZ_THEME_PATH}"
log SUCCESS "Ownership fixed."

# 5. Fix permissions
log INFO "5. Fixing permissions for ${NC_SAVAREZ_THEME_PATH}..."
run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type d -exec chmod 755 {} \;"
run_remote_cmd "$SERVER" "$USERNAME" "sudo find ${NC_SAVAREZ_THEME_PATH} -type f -exec chmod 644 {} \;"
log SUCCESS "Permissions fixed."

# 6. Clear Nextcloud cache
log INFO "6. Clearing Nextcloud cache..."
# Disable/enable to force theme re-scan and clear caches
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:disable ${SAVAREZ_THEME_APP_NAME} --force > /dev/null 2>&1 || true"
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ app:enable ${SAVAREZ_THEME_APP_NAME}"
run_remote_cmd "$SERVER" "$USERNAME" "sudo -u ${WEB_USER} php ${NC_APP_DIR}/occ cache:clear"
log SUCCESS "Nextcloud cache cleared and app re-enabled."

# 7. Restart Apache (unless skipped)
if ! $NO_RESTART; then
    log INFO "7. Restarting web service (${WEB_SERVICE_NAME})..."
    run_remote_cmd "$SERVER" "$USERNAME" "sudo systemctl restart ${WEB_SERVICE_NAME}"
    log SUCCESS "Web service restarted."
else
    log WARN "7. Skipping web service restart as requested."
fi

# 8. Verify deployment with verify.sh
log INFO "8. Verifying deployment..."
# We will call verify.sh as a sub-process to utilize its comprehensive checks.
# It's crucial for verify.sh to have a proper exit code.
if "$(dirname "${BASH_SOURCE[0]}")"/verify.sh "$SERVER" "$USERNAME"; then
    log SUCCESS "Deployment verification passed."
else
    log ERROR "Deployment verification FAILED. Initiating rollback."
    DEPLOY_STATUS=1
    exit 1 # Trigger trap for rollback
fi

# 9. (Optional) Purge Cloudflare cache
log INFO "9. Cloudflare purge needs to be done manually or via purge-cache.sh if necessary."

DEPLOY_STATUS=0 # If we reach here, deployment is successful
log SUCCESS "Deployment pipeline finished successfully!"
