#!/usr/bin/env bash
# File: preview-session.sh
# Description: Render session preview
# Dependencies: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# Constants
# ====================================================================

readonly BOX_WIDTH=60
readonly PREVIEW_LINES=15
PREVIEW_REFRESH_MS="${PREVIEW_REFRESH_MS:-0}"

# ====================================================================
# Function definitions
# ====================================================================

# Function: print_header
# Description: Render header box
# Args:
#   $1 - session name
# Returns: 0
# Output: header box
print_header() {
    local session_name="$1"
    local name_display
    name_display=$(truncate_string "$session_name" $((BOX_WIDTH - 15)))

    local inner_width=$((BOX_WIDTH - 1))
    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    printf "\033[1;35m║\033[0m \033[1;36m%-*s\033[0m\033[1;35m║\033[0m\n" \
        "$inner_width" "  Session: ${name_display}"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# Function: get_session_info
# Description: Fetch basic session info
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
# Output: session info (pipe-delimited)
get_session_info() {
    local session_name="$1"

    local info
    info=$(tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_windows}|#{session_created}|#{session_activity}" 2>/dev/null | \
        grep "^${session_name}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Session not found: $session_name"
        return 1
    fi

    echo "$info"
}

# Function: print_session_info
# Description: Show session info
# Args:
#   $1 - session_name
#   $2 - attached
#   $3 - windows
#   $4 - created
#   $5 - activity
# Returns: 0
# Output: formatted session info
print_session_info() {
    local session_name="$1"
    local attached="$2"
    local windows="$3"
    local created="$4"
    local activity="$5"

    local status
    [[ $attached -gt 0 ]] && status="attached" || status="detached"

    local created_ago
    created_ago=$(format_time_ago "$created")

    local activity_ago
    activity_ago=$(format_time_ago "$activity")

    echo -e "\033[1;34m┌─ Info\033[0m"
    echo -e "\033[1;34m├─\033[0m Status:       \033[1;33m${status}\033[0m"
    echo -e "\033[1;34m├─\033[0m Windows:      \033[1;32m${windows}\033[0m"
    echo -e "\033[1;34m├─\033[0m Created:      \033[2m${created_ago} ago\033[0m"
    echo -e "\033[1;34m└─\033[0m Last Activity: \033[2m${activity_ago} ago\033[0m"
    echo
}

# Function: get_windows
# Description: Fetch window list
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
# Output: window info (pipe-delimited)
get_windows() {
    local session_name="$1"

    tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}|#{window_active}" \
        2>/dev/null || {
        log_error "Failed to get windows for session: $session_name"
        return 1
    }
}

# Function: print_windows
# Description: Show window list
# Args:
#   $1 - session name
# Returns: 0
# Output: formatted window list
print_windows() {
    local session_name="$1"

    echo -e "\033[1;34m┌─ Windows\033[0m"

    local windows
    windows=$(get_windows "$session_name")

    echo "$windows" | while IFS='|' read -r idx name panes active; do
        local marker color
        if [[ "$active" == "1" ]]; then
            marker="❯"
            color="\033[1;32m"
        else
            marker="│"
            color="\033[2m"
        fi

        local display_name
        display_name=$(truncate_string "$name" 30)

        printf "%b%s %2d: %-30s \033[2m[%dP]\033[0m\n" \
            "$color" "$marker" "$idx" "$display_name" "$panes"
    done

    echo
}

# Function: print_active_pane_preview
# Description: Show active window pane preview
# Args:
#   $1 - session name
# Returns: 0
# Output: pane content preview
print_active_pane_preview() {
    local session_name="$1"

    local active_window
    active_window=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_active}" 2>/dev/null | \
        grep "|1$" | cut -d'|' -f1 | head -1)

    if [[ -z "$active_window" ]]; then
        log_warn "No active window found"
        return 0
    fi

    local window_name
    window_name=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}" 2>/dev/null | \
        grep "^${active_window}|" | cut -d'|' -f2)

    echo -e "\033[1;34m Active Window Preview: \033[1;36m${window_name}\033[0m"

    if ! tmux capture-pane -t "${session_name}:${active_window}.0" -J -N -e -p 2>/dev/null; then
        echo -e "\033[1;34m│\033[0m   \033[2m(Preview not available)\033[0m"
    fi
}

# Function: render_preview
# Description: Render preview once
# Args:
#   $1 - session name
# Returns: 0 success / 1 failure
render_preview() {
    local session_name="$1"

    log_debug "Generating preview for session: $session_name"

    local info
    if ! info=$(get_session_info "$session_name"); then
        echo "Error: Session not found"
        return 1
    fi

    IFS='|' read -r name attached windows created activity <<< "$info"

    print_header "$name"
    print_session_info "$name" "$attached" "$windows" "$created" "$activity"
    print_windows "$name"
    print_active_pane_preview "$name"

    log_debug "Preview generated successfully"
    return 0
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate session preview (optionally looping)
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
main() {
    local session_name="$1"
    local refresh_ms="$PREVIEW_REFRESH_MS"

    # Validate number; treat non-numeric as 0
    if ! [[ "$refresh_ms" =~ ^[0-9]+$ ]]; then
        refresh_ms=0
    fi

    if (( refresh_ms > 0 )); then
        local interval_sec
        interval_sec=$(awk -v ms="$refresh_ms" 'BEGIN {printf "%.3f", ms/1000}')
        trap 'exit 0' INT TERM
        while true; do
            # clear the screen then redraw
            printf '\033[H\033[2J'
            if ! render_preview "$session_name"; then
                sleep "$interval_sec"
                continue
            fi
            sleep "$interval_sec"
        done
    else
        render_preview "$session_name"
    fi
}

# Argument check
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <session_name>"
    exit 1
fi

main "$@"
