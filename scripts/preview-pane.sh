#!/usr/bin/env bash
# File: preview-pane.sh
# Description: Render pane preview
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
readonly PREVIEW_LINES=50

# ====================================================================
# Function definitions
# ====================================================================

# Function: print_header
# Description: Render header box
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - paneindex
# Returns: 0
# Output: header box
print_header() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    local title="${session_name}:${window_index}.${pane_index}"

    local inner_width=$((BOX_WIDTH - 1))
    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    printf "\033[1;35m║\033[0m \033[1;36m%-*s\033[0m\033[1;35m║\033[0m\n" \
        "$inner_width" "  Pane: ${title}"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# Function: get_pane_info
# Description: Fetch pane metadata
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - paneindex
# Returns:
#   0 - success
#   1 - error
# Output: pane info (pipe-delimited)
get_pane_info() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    local info
    info=$(tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_current_path}|#{pane_pid}" \
        2>/dev/null | grep "^${pane_index}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Pane not found: $session_name:$window_index.$pane_index"
        return 1
    fi

    echo "$info"
}

# Function: print_pane_info
# Description: Show pane metadata
# Args:
#   $1 - command
#   $2 - width
#   $3 - height
#   $4 - path
#   $5 - pid
# Returns: 0
# Output: formatted pane info
print_pane_info() {
    local cmd="$1"
    local width="$2"
    local height="$3"
    local path="$4"
    local pid="$5"

    echo -e "\033[1;34m┌─ Info\033[0m"
    echo -e "\033[1;34m├─\033[0m Command:      \033[1;33m${cmd}\033[0m"
    echo -e "\033[1;34m├─\033[0m Size:         \033[1;32m${width}x${height}\033[0m"
    echo -e "\033[1;34m├─\033[0m Path:         \033[2m${path}\033[0m"
    echo -e "\033[1;34m└─\033[0m PID:          \033[2m${pid}\033[0m"
    echo
}

# Function: print_pane_content
# Description: Show pane content
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - paneindex
# Returns: 0
# Output: pane content
print_pane_content() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    echo -e "\033[1;34m Content (last ${PREVIEW_LINES} lines)\033[0m"
    if ! tmux capture-pane -t "${session_name}:${window_index}.${pane_index}" -J -N -e -p -S - 2>/dev/null; then
        echo -e "\033[1;34m│\033[0m \033[2m(Content not available)\033[0m"
    fi
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate pane preview
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - paneindex
# Returns:
#   0 - success
#   1 - error
main() {
    local session_name="${1:-}"
    local window_index="${2:-}"
    local pane_index="${3:-}"

    if [[ -z "$session_name" ]] || [[ -z "$window_index" ]] || [[ -z "$pane_index" ]]; then
        echo "Usage: $0 <session_name> <window_index> <pane_index>"
        return 1
    fi

    log_debug "Generating preview for pane: $session_name:$window_index.$pane_index"

    local info
    if ! info=$(get_pane_info "$session_name" "$window_index" "$pane_index"); then
        echo "Error: Pane not found"
        return 1
    fi

    IFS='|' read -r idx cmd width height path pid <<< "$info"

    print_header "$session_name" "$window_index" "$idx"
    print_pane_info "$cmd" "$width" "$height" "$path" "$pid"
    print_pane_content "$session_name" "$window_index" "$idx"

    log_debug "Preview generated successfully"
    return 0
}

main "$@"
