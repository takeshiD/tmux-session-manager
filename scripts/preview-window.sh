#!/usr/bin/env bash
# File: preview-window.sh
# Description: Render window preview
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
readonly PANE_PREVIEW_LINES=8

# Decide per-pane content lines based on available preview height; keep bottom part.
get_per_pane_lines() {
    local panes="$1"
    local preview_env="${FZF_PREVIEW_LINES:-0}"
    local fallback="$PANE_PREVIEW_LINES"

    # header 4 lines + pane list block (1 header + panes rows + 1 blank)
    local header_lines=4
    local list_lines=$((1 + panes + 1))
    local static=$((header_lines + list_lines))

    if [[ "$preview_env" =~ ^[0-9]+$ ]]; then
        local available=$((preview_env - static))
        # per pane overhead: title line + blank line ≈2
        if (( available > (2 * panes + 1) )); then
            local per=$((available / panes - 2))
            if (( per < 3 )); then
                per=3
            fi
            echo "$per"
            return
        fi
    fi

    echo "$fallback"
}

# ====================================================================
# Function definitions
# ====================================================================

# Function: print_header
# Description: Render header box
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - window name
# Returns: 0
# Output: header box
print_header() {
    local session_name="$1"
    local window_index="$2"
    local window_name="$3"

    local title="${session_name}:${window_index} - ${window_name}"
    local title_display
    title_display=$(truncate_string "$title" $((BOX_WIDTH - 10)))

    local inner_width=$((BOX_WIDTH))
    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    printf "\033[1;35m║\033[0m \033[1;36m%-*s\033[0m\033[1;35m║\033[0m\n" \
        "$inner_width" "  Window: ${title_display}"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# Function: get_window_info
# Description: Fetch window metadata
# Args:
#   $1 - session name
#   $2 - windowindex
# Returns:
#   0 - success
#   1 - error
# Output: window info (pipe-delimited)
get_window_info() {
    local session_name="$1"
    local window_index="$2"

    local info
    info=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}" 2>/dev/null | \
        grep "^${window_index}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Window not found: $session_name:$window_index"
        return 1
    fi

    echo "$info"
}

# Function: print_panes_list
# Description: Show pane list
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - pane count
# Returns: 0
# Output: pane list
print_panes_list() {
    local session_name="$1"
    local window_index="$2"
    local panes="$3"

    echo -e "\033[1;34m┌─ Panes (${panes})\033[0m"

    local panes_info
    panes_info=$(tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_active}" \
        2>/dev/null)

    echo "$panes_info" | while IFS='|' read -r idx cmd width height active; do
        local marker color
        if [[ "$active" == "1" ]]; then
            marker="❯"
            color="\033[1;32m"
        else
            marker="│"
            color="\033[2m"
        fi

        local icon
        case "$cmd" in
            vim|nvim) icon="📝" ;;
            bash|zsh|fish) icon="🐚" ;;
            ssh) icon="🔐" ;;
            *) icon="⚙️ " ;;
        esac

        printf "%b%s %d: %s %-15s \033[2m(%dx%d)\033[0m\n" \
            "$color" "$marker" "$idx" "$icon" "$cmd" "$width" "$height"
    done

    echo
}

# Function: print_panes_preview
# Description: Show preview for each pane
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - pane count
# Returns: 0
# Output: pane content previews
print_panes_preview() {
    local session_name="$1"
    local window_index="$2"
    local panes="$3"

    local per_pane_lines
    per_pane_lines=$(get_per_pane_lines "$panes")

    for i in $(seq 0 $((panes - 1))); do
        local cmd
        cmd=$(tmux display-message -t "${session_name}:${window_index}.${i}" -p "#{pane_current_command}" 2>/dev/null)

        echo -e "\033[1;34m├─ Pane $i ($cmd):\033[0m"

        if ! tmux capture-pane -t "${session_name}:${window_index}.${i}" -e -p 2>/dev/null | \
            tail -n "$per_pane_lines" | \
            while IFS= read -r line; do
                echo -e "\033[1;34m│\033[0m   $line"
            done; then
            echo -e "\033[1;34m│\033[0m   \033[2m(Preview not available)\033[0m"
        fi
        echo
    done
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Generate window preview
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

    log_debug "Generating preview for window: $session_name:$window_index"

    local info
    if ! info=$(get_window_info "$session_name" "$window_index"); then
        echo "Error: Window not found"
        return 1
    fi

    IFS='|' read -r idx name panes <<< "$info"

    print_header "$session_name" "$idx" "$name"
    print_panes_list "$session_name" "$idx" "$panes"
    print_panes_preview "$session_name" "$idx" "$panes"

    log_debug "Preview generated successfully"
    return 0
}

main "$@"
