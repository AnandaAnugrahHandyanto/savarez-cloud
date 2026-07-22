# scripts/lib/config.sh

# Define global configuration variables for Savarez Cloud Theme Development

# --- Production Server Configuration ---
# Base path for Nextcloud installation on the production server
export NC_APP_DIR="/srv/nextcloud-app"

# Nextcloud app name for Savarez Theme
export SAVAREZ_THEME_APP_NAME="savarez_theme"

# Full path to the Savarez Theme app on production
export NC_SAVAREZ_THEME_PATH="${NC_APP_DIR}/apps/${SAVAREZ_THEME_APP_NAME}"

# ROOT path of the repository
# config.sh is located in scripts/lib/, so we need to go up two levels
export REPO_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# Local development app path
export LOCAL_APP_PATH="${REPO_ROOT}/app"

# Local backups directory
export LOCAL_BACKUPS_DIR="${REPO_ROOT}/backups"

# Local snapshots directory
export LOCAL_SNAPSHOTS_DIR="${REPO_ROOT}/snapshots"

# Nextcloud data directory on production (for occ commands)
export NC_DATA_DIR="${NC_APP_DIR}/data"

# Apache/PHP-FPM service name
export WEB_SERVICE_NAME="apache2"

# Nextcloud web server user/group
export WEB_USER="www-data"
export WEB_GROUP="www-data"

# Cloudflare API Configuration (Placeholder)
# export CLOUDFLARE_API_KEY=***
# export CLOUDFLARE_EMAIL=""
# export CLOUDFLARE_ZONE_ID=""
# export CLOUDFLARE_HOST="your_nextcloud_domain.com"
