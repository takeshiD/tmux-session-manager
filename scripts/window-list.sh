#!/usr/bin/env bash
# File: window-list.sh
# Description: Generate a list of windows for a session
# Dependencies: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# Function definitions
# ====================================================================

# Function: get_windows
# Description: Fetch window metadata for a session
# Args:
#   $1 - session name
# Returns:
#   0 on success
#   1 on error
# Output: window info as pipe-delimited lines
get_windows() {
    local session_name="$1"

    tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}|#{window_active}" \
        2>/dev/null || {
        log_error "Failed to get windows for session: $session_name"
        return 1
    }
}

# Function: get_layout_icon
# Description: Return a layout icon based on pane count
# Args:
#   $1 - pane count
# Returns: 0
# Output: layout icon character
get_layout_icon() {
    local panes="$1"

    if [[ $panes -eq 1 ]]; then
        echo "▢"  # single pane
    else
        echo "⊞"  # multiple panes
    fi
}

# Function: format_window_line
# Description: Format one window line for fzf
# Args:
#   $1 - index
#   $2 - name
#   $3 - panes
#   $4 - active
# Returns: 0
# Output: formatted line
format_window_line() {
    local index="$1"
    local name="$2"
    local panes="$3"
    local active="$4"

    local marker color
    if [[ "$active" == "1" ]]; then
        marker="❯"
        color="\033[1;32m"
    else
        marker=" "
        color="\033[0m"
    fi

    local layout_icon
    layout_icon=$(get_layout_icon "$panes")

    local display_name
    display_name=$(truncate_string "$name" 25)
    display_name=$(printf "%-25s" "$display_name")

    # Output format: "<index>\t<display text>" so fzf can use index as the first field
    printf "%s\t%b%s %s %s \033[2m[%dP]\033[0m\n" \
        "$index" "$color" "$marker" "$display_name" "$layout_icon" "$panes"
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate window list and print to stdout
# Args:
#   $1 - session name
# Returns:
#   0 on success
#   1 on error
main() {
    local session_name="${1:-}"

    if [[ -z "$session_name" ]]; then
        echo "Usage: $0 <session_name>"
        return 1
    fi

    log_debug "Generating window list for session: $session_name"

    local windows
    if ! windows=$(get_windows "$session_name"); then
        log_error "Failed to get windows"
        echo "No windows available"
        return 1
    fi

    echo "$windows" | while IFS='|' read -r index name panes active; do
        format_window_line "$index" "$name" "$panes" "$active"
    done

    log_debug "Window list generated successfully"
    return 0
}

main "$@"
