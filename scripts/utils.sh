#!/usr/bin/env bash
# File: utils.sh
# Description: Common utility functions
# Dependencies: none

# ====================================================================
# Globals
# ====================================================================

# Log level map
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
)

# Current log level (env override, default INFO)
CURRENT_LOG_LEVEL="${TMUX_SESSION_MANAGER_LOG_LEVEL:-INFO}"
LOG_FILE="${TMUX_SESSION_MANAGER_LOG_FILE:-/tmp/tmux-session-manager.log}"

# ====================================================================
# Logging
# ====================================================================

# Function: log_message
# Description: Append a log line (and show tmux message on ERROR)
# Args:
#   $1 - log level (DEBUG/INFO/WARN/ERROR)
#   $@ - message
# Returns: none
# Output: writes to log file, shows tmux message on ERROR
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ ${LOG_LEVELS[$level]:-0} -ge ${LOG_LEVELS[$CURRENT_LOG_LEVEL]:-1} ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"

        if [[ "$level" == "ERROR" ]]; then
            tmux display-message "[Error] ${message}" 2>/dev/null || true
        fi
    fi
}

log_debug() { log_message DEBUG "$@"; }
log_info()  { log_message INFO "$@"; }
log_warn()  { log_message WARN "$@"; }
log_error() { log_message ERROR "$@"; }

# ====================================================================
# Time helpers
# ====================================================================

# Function: format_time_ago
# Description: Format elapsed time from Unix timestamp
# Args:
#   $1 - Unix timestamp
# Returns: 0
# Output: formatted string like "2h", "30m", "3d"
format_time_ago() {
    local timestamp="$1"
    local now
    now=$(date +%s)
    local diff=$((now - timestamp))

    if [[ $diff -lt 60 ]]; then
        echo "${diff}s"
    elif [[ $diff -lt 3600 ]]; then
        echo "$((diff / 60))m"
    elif [[ $diff -lt 86400 ]]; then
        echo "$((diff / 3600))h"
    else
        echo "$((diff / 86400))d"
    fi
}

# ====================================================================
# Icons
# ====================================================================

# Function: get_icon
# Description: Icon for session state
# Args:
#   $1 - session_name
#   $2 - is_attached (0 or >0)
#   $3 - is_current (0 or 1)
# Returns: 0
# Output: icon + color code
get_icon() {
    local session_name="$1"
    local is_attached="$2"
    local is_current="$3"

    if [[ "$is_current" == "1" ]]; then
        echo -e "\033[1;32m📝\033[0m"  # green edit icon
    elif [[ "$is_attached" -gt 0 ]]; then
        echo -e "\033[1;33m📎\033[0m"  # yellow clip
    else
        echo -e "\033[2;37m💤\033[0m"  # gray sleep
    fi
}

# ====================================================================
# Activity markers
# ====================================================================

# Function: get_activity_marker
# Description: Marker based on last activity time
# Args:
#   $1 - last activity (Unix timestamp)
# Returns: 0
# Output: marker (🔥 / ⚡ / blank)
get_activity_marker() {
    local activity="$1"
    local now
    now=$(date +%s)
    local diff=$((now - activity))

    if [[ $diff -lt 300 ]]; then      # within 5 minutes
        echo "🔥"
    elif [[ $diff -lt 3600 ]]; then   # within 1 hour
        echo "⚡"
    else
        echo "  "
    fi
}

# ====================================================================
# Validation
# ====================================================================

# Function: validate_session_name
# Description: Validate session name
# Args:
#   $1 - session name
# Returns:
#   0 - valid
#   1 - invalid
# Output: error message on invalid
validate_session_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        log_error "Session name cannot be empty"
        return 1
    fi

    if [[ "$name" == *:* ]]; then
        log_error "Session name cannot contain ':'"
        return 1
    fi

    if [[ ${#name} -gt 50 ]]; then
        log_error "Session name too long (max 50 characters)"
        return 1
    fi

    return 0
}

# ====================================================================
# String helpers
# ====================================================================

# Function: truncate_string
# Description: Truncate string to given length
# Args:
#   $1 - string
#   $2 - max length
# Returns: 0
# Output: truncated string
truncate_string() {
    local str="$1"
    local max_len="$2"

    if [[ ${#str} -le $max_len ]]; then
        echo "$str"
    else
        echo "${str:0:$((max_len - 3))}..."
    fi
}

# ====================================================================
# Dependency checks
# ====================================================================

# Function: version_compare
# Description: Compare version numbers
# Args:
#   $1 - version 1
#   $2 - version 2 (minimum required)
# Returns:
#   0 - version1 >= version2
#   1 - version1 < version2
version_compare() {
    local version1="$1"
    local version2="$2"

    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

# Function: check_dependencies
# Description: Verify required commands and versions
# Args: none
# Returns:
#   0 - all dependencies available
#   1 - missing dependencies
# Output: error messages when missing
check_dependencies() {
    local missing_deps=()
    local errors=0

    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
        errors=1
    else
        local tmux_version
        tmux_version=$(tmux -V | cut -d' ' -f2 | tr -d 'a-z')

        if ! version_compare "$tmux_version" "3.2"; then
            log_error "tmux version 3.2 or higher required (found: $tmux_version)"
            errors=1
        fi
    fi

    if ! command -v fzf &> /dev/null; then
        missing_deps+=("fzf")
        errors=1
    else
        local fzf_version
        fzf_version=$(fzf --version | cut -d' ' -f1)

        if ! version_compare "$fzf_version" "0.30.0"; then
            log_warn "fzf version 0.30.0 or higher recommended (found: $fzf_version)"
        fi
    fi

    local bash_version="${BASH_VERSION%%.*}"
    if [[ $bash_version -lt 4 ]]; then
        log_error "bash version 4.0 or higher required (found: $BASH_VERSION)"
        errors=1
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        errors=1
    fi

    return $errors
}

# ====================================================================
# Error handling
# ====================================================================

# Function: safe_tmux
# Description: Safe wrapper around tmux command
# Args:
#   $@ - tmux command args
# Returns:
#   tmux exit code
# Output: tmux stdout/stderr
safe_tmux() {
    local output
    local exit_code

    if ! output=$(tmux "$@" 2>&1); then
        exit_code=$?
        log_error "tmux command failed: tmux $*"
        log_error "Output: $output"
        return $exit_code
    fi

    echo "$output"
    return 0
}
