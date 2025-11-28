#!/usr/bin/env bash
# File: pane-list.sh
# Description: Generate pane list
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

# Function: get_panes
# Description: Fetch pane info
# Args:
#   $1 - session name
#   $2 - windowindex
# Returns:
#   0 - success
#   1 - error
# Output: pane info (pipe-delimited)
get_panes() {
    local session_name="$1"
    local window_index="$2"

    tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_active}" \
        2>/dev/null || {
        log_error "Failed to get panes for window: $session_name:$window_index"
        return 1
    }
}

# Function: get_command_icon
# Description: Return an icon based on the command name
# Args:
#   $1 - command name
# Returns: 0
# Output: icon character
get_command_icon() {
    local cmd="$1"

    case "$cmd" in
        vim|nvim) echo "📝" ;;
        bash|zsh|fish) echo "🐚" ;;
        ssh) echo "🔐" ;;
        python*) echo "🐍" ;;
        node|npm) echo "📦" ;;
        docker) echo "🐳" ;;
        *) echo "⚙️ " ;;
    esac
}

# Function: format_pane_line
# Description: Format one pane line for fzf
# Args:
#   $1 - index
#   $2 - command
#   $3 - width
#   $4 - height
#   $5 - active
# Returns: 0
# Output: formatted line
format_pane_line() {
    local index="$1"
    local cmd="$2"
    local width="$3"
    local height="$4"
    local active="$5"

    local marker color
    if [[ "$active" == "1" ]]; then
        marker="❯"
        color="\033[1;32m"
    else
        marker=" "
        color="\033[0m"
    fi

    local icon
    icon=$(get_command_icon "$cmd")

    local display_cmd
    display_cmd=$(truncate_string "$cmd" 15)
    display_cmd=$(printf "%-15s" "$display_cmd")

    # Output format: "<index>\t<display string>"
    printf "%s\t%b%s %s %s \033[2m(%dx%d)\033[0m\n" \
        "$index" "$color" "$marker" "$icon" "$display_cmd" "$width" "$height"
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate pane list and print to stdout
# Args:
#   $1 - session name
#   $2 - windowindex
# Returns:
#   0 - success
#   1 - error
main() {
    local session_name="${1:-}"
    local window_index="${2:-}"

    if [[ -z "$session_name" ]] || [[ -z "$window_index" ]]; then
        echo "Usage: $0 <session_name> <window_index>"
        return 1
    fi

    log_debug "Generating pane list for window: $session_name:$window_index"

    local panes
    if ! panes=$(get_panes "$session_name" "$window_index"); then
        log_error "Failed to get panes"
        echo "No panes available"
        return 1
    fi

    echo "$panes" | while IFS='|' read -r index cmd width height active; do
        format_pane_line "$index" "$cmd" "$width" "$height" "$active"
    done

    log_debug "Pane list generated successfully"
    return 0
}

main "$@"
