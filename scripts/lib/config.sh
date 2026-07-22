# scripts/lib/config.sh

# Define global configuration variables for Savarez Cloud Theme Development

# --- Production Server Configuration ---
# These values should ideally be passed as environment variables or arguments
# For simplicity in initial script, direct assignment here, but recommend dynamic input.
# export NC_PROD_SERVER="your_production_server.com"
# export NC_PROD_USERNAME="your_ssh_username"

# Base path for Nextcloud installation on the production server
export NC_APP_DIR="/srv/nextcloud-app"

# Nextcloud app name for Savarez Theme
export SAVAREZ_THEME_APP_NAME="savarez_theme"

# Full path to the Savarez Theme app on production
export NC_SAVAREZ_THEME_PATH="${NC_APP_DIR}/apps/${SAVAREZ_THEME_APP_NAME}"

# Local development app path
export LOCAL_APP_PATH="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"/app"

# Local backups directory
export LOCAL_BACKUPS_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"/backups"

# Local snapshots directory
export LOCAL_SNAPSHOTS_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"/snapshots"

# Nextcloud data directory on production (for occ commands)
export NC_DATA_DIR="${NC_APP_DIR}/data"

# Apache/PHP-FPM service name (adjust if different, e.g., nginx, php-fpm)
export WEB_SERVICE_NAME="apache2"

# Nextcloud web server user/group
export WEB_USER="www-data"
export WEB_GROUP="www-data"

# Cloudflare API Configuration (Placeholder - DO NOT HARDCODE TOKENS)
# export CLOUDFLARE_API_KEY=""
# export CLOUDFLARE_EMAIL=""
# export CLOUDFLARE_ZONE_ID=""
# export CLOUDFLARE_HOST="your_nextcloud_domain.com"
