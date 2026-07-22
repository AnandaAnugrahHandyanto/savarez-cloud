# scripts/lib/common.sh

# Source common libraries
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Function to log messages
log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    case "$LEVEL" in
        INFO)
            echo -e "${GREEN}[$TIMESTAMP][INFO]${NC} ${MESSAGE}"
            ;;
        WARN)
            echo -e "${YELLOW}[$TIMESTAMP][WARN]${NC} ${MESSAGE}"
            ;;
        ERROR)
            echo -e "${RED}[$TIMESTAMP][ERROR]${NC} ${MESSAGE}"
            ;;
        SUCCESS)
            echo -e "${CYAN}[$TIMESTAMP][SUCCESS]${NC} ${MESSAGE}"
            ;;
        *)
            echo -e "${BLUE}[$TIMESTAMP][DEBUG]${NC} ${LEVEL} ${MESSAGE}"
            ;;
    esac
}

# Function to handle errors and exit
error_exit() {
    log ERROR "$1"
    exit 1
}

# Function to run a command remotely via SSH
run_remote_cmd() {
    local SERVER="$1"
    local USERNAME="$2"
    local COMMAND="$3"
    local SILENT="$4"

    if [ -z "$SILENT" ]; then
        log INFO "Executing remote command on ${USERNAME}@${SERVER}: ${COMMAND}"
        ssh "${USERNAME}@${SERVER}" "$COMMAND"
    else
        ssh "${USERNAME}@${SERVER}" "$COMMAND" > /dev/null 2>&1
    fi

    if [ $? -ne 0 ]; then
        error_exit "Remote command failed on ${SERVER}: ${COMMAND}"
    fi
}

# Function to copy files remotely via SCP
copy_remote_file() {
    local SOURCE_PATH="$1"
    local DEST_PATH="$2"
    local SERVER="$3"
    local USERNAME="$4"
    log INFO "Copying ${SOURCE_PATH} to ${USERNAME}@${SERVER}:${DEST_PATH}"
    scp -r "$SOURCE_PATH" "${USERNAME}@${SERVER}:${DEST_PATH}"
    if [ $? -ne 0 ]; then
        error_exit "SCP failed to copy ${SOURCE_PATH} to ${SERVER}:${DEST_PATH}"
    fi
}

# Function to get current timestamp for backups
get_timestamp() {
    date +"%Y%m%d%H%M%S"
}

# Function to check for required command line dependencies
check_dependencies() {
    local DEPENDENCIES=("$@")
    local MISSING_DEPS=()
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            MISSING_DEPS+=("$dep")
        fi
    done

    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        error_exit "Missing required dependencies: ${MISSING_DEPS[*]}"
    fi
    log SUCCESS "All required dependencies found."
}
