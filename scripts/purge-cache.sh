#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 <purge_url_or_all>${NC}"
    echo -e "${YELLOW}  purge_url_or_all: Specify a URL to purge (e.g., https://your_domain.com/apps/savarez_theme/css/style.css)"${NC}"
    echo -e "${YELLOW}                    or use 'all' to purge all files for the configured Cloudflare zone.${NC}"
    echo -e "\n${YELLOW}  Cloudflare API Key, Email, and Zone ID must be set as environment variables:${NC}"
    echo -e "${YELLOW}    CLOUDFLARE_API_KEY, CLOUDFLARE_EMAIL, CLOUDFLARE_ZONE_ID${NC}"
    echo -e "${YELLOW}  Alternatively, they can be configured in scripts/lib/config.sh (NOT RECOMMENDED for sensitive tokens).${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 1 ]; then
    usage
fi

PURGE_TARGET="$1"

# Read Cloudflare config from environment or config.sh (env takes precedence)
CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY:-${CF_API_KEY}}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL:-${CF_EMAIL}}
CLOUDFLARE_ZONE_ID=${CLOUDFLARE_ZONE_ID:-${CF_ZONE_ID}}
CLOUDFLARE_HOST=${CLOUDFLARE_HOST:-${CF_HOST}}

# Validate Cloudflare configuration
if [ -z "$CLOUDFLARE_API_KEY" ] || [ -z "$CLOUDFLARE_EMAIL" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    error_exit "Cloudflare API Key, Email, or Zone ID not set. Please set them as environment variables or in config.sh."
fi

log INFO "Starting Cloudflare cache purge..."

# --- Purge Logic ---
if [ "$PURGE_TARGET" == "all" ]; then
    log INFO "Purging ALL files for Cloudflare Zone ID: ${CLOUDFLARE_ZONE_ID}"
    PAYLOAD='{"purge_everything":true}'
else
    log INFO "Purging URL: ${PURGE_TARGET}"
    PAYLOAD='{"files":["'"${PURGE_TARGET}"'"]}'
fi

RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
     -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
     -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
     -H "Content-Type: application/json" \
     --data "$PAYLOAD")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" == "true" ]; then
    log SUCCESS "Cloudflare cache purge successful."
    log INFO "Response: ${RESPONSE}"
else
    log ERROR "Cloudflare cache purge failed."
    log ERROR "Response: ${RESPONSE}"
    error_exit "Cloudflare purge command failed."
fi

log SUCCESS "Cloudflare cache purge process completed."
