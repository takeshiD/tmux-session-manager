#!/usr/bin/env bash
# File: session-list.sh
# Description: Generate list of tmux sessions
# Dependencies: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# Globals
# ====================================================================

CURRENT_SESSION=""

# ====================================================================
# Function definitions
# ====================================================================

# Function: get_sessions
# Description: Fetch session metadata
# Args: none
# Returns:
#   0 on success
#   1 on error
# Output: session info as pipe-delimited lines
get_sessions() {
    tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}|#{session_activity}" 2>/dev/null || {
        log_error "Failed to get session list"
        return 1
    }
}

# Function: get_current_session
# Description: Fetch current session name
# Args: none
# Returns: 0
# Output: current session name
get_current_session() {
    tmux display-message -p '#S' 2>/dev/null || echo ""
}

# Function: sort_sessions
# Description: Sort sessions (current → attached → detached)
# Args:
#   $1 - current session name
# Returns: 0
# Output: sorted session info
sort_sessions() {
    local current="$1"
    local sessions
    sessions=$(cat)

    {
        echo "$sessions" | awk -F '|' -v cur="$current" '($1==cur)'
        echo "$sessions" | awk -F '|' -v cur="$current" '($1!=cur && $3>0)'
        echo "$sessions" | awk -F '|' -v cur="$current" '($1!=cur && $3==0)'
    }
}

# Function: format_session_line
# Description: Format one session line for fzf
# Args:
#   $1 - name
#   $2 - windows
#   $3 - attached
#   $4 - created
#   $5 - activity
# Returns: 0
# Output: formatted line
format_session_line() {
    local name="$1"
    local windows="$2"
    local attached="$3"
    local created="$4"
    local activity="$5"

    local is_current=0
    [[ "$name" == "$CURRENT_SESSION" ]] && is_current=1
    local icon
    icon=$(get_icon "$name" "$attached" "$is_current")

    local activity_marker
    activity_marker=$(get_activity_marker "$activity")

    local time_ago
    time_ago=$(format_time_ago "$activity")

    local display_name
    display_name=$(printf "%-20s" "$name")

    local color_code=""
    local reset="\033[0m"

    if [[ $is_current -eq 1 ]]; then
        color_code="\033[1;32m"  # green bold
    elif [[ $attached -gt 0 ]]; then
        color_code="\033[1;33m"  # yellow bold
    else
        color_code="\033[2;37m"  # dim gray
    fi

    printf "%b%s%b  %s %s \033[2m[%2dW]\033[0m  \033[2m%s\033[0m\n" \
        "$color_code" "$display_name" "$reset" \
        "$icon" "$activity_marker" \
        "$windows" "$time_ago"
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate session list and print to stdout
# Args: none
# Returns:
#   0 on success
#   1 on error
main() {
    log_debug "Generating session list"

    CURRENT_SESSION=$(get_current_session)
    log_debug "Current session: $CURRENT_SESSION"

    local sessions
    if ! sessions=$(get_sessions); then
        log_error "No sessions found"
        echo "No tmux sessions available"
        return 1
    fi

    echo "$sessions" | sort_sessions "$CURRENT_SESSION" | \
    while IFS='|' read -r name windows attached created activity; do
        format_session_line "$name" "$windows" "$attached" "$created" "$activity"
    done

    log_debug "Session list generated successfully"
    return 0
}

main "$@"
