#!/usr/bin/env bash
# File: detail-mode.sh
# Description: Window selection mode
# Dependencies: config.sh, utils.sh, window-list.sh, preview-window.sh

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

# Function: build_fzf_options
# Description: Build fzf options
# Args:
#   $1 - session name
# Returns: 0
# Output: fzf option string
build_fzf_options() {
    local session_name="$1"
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    # Keep header compact (~80 chars)
    local header="Session:${session_name} | ⏎ switch | ␣ panes | ESC back | C-/ preview"
    local prompt="🪟 Windows > "

    echo "$base_options \
        --delimiter='\t' \
        --with-nth=2 \
        --header='$header' \
        --prompt='$prompt' \
        --preview='bash ${CURRENT_DIR}/preview-window.sh ${session_name} {1}' \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch-window ${session_name} {1})' \
        --bind='space:execute(bash ${CURRENT_DIR}/pane-mode.sh ${session_name} {1})+abort' \
        --bind='ctrl-/:toggle-preview' \
        --bind='esc:abort' \
        --bind='q:abort'"
}

# Function: switch_to_window
# Description: Switch to the specified window
# Args:
#   $1 - session name
#   $2 - windowindex
# Returns:
#   0 - success
#   1 - error
switch_to_window() {
    local session_name="$1"
    local window_index="$2"

    log_info "Switching to window: $session_name:$window_index"

    if ! tmux select-window -t "${session_name}:${window_index}" 2>/dev/null; then
        log_error "Failed to select window: $session_name:$window_index"
        tmux display-message "Error: Failed to switch to window"
        return 1
    fi

    # Also switch the client to the session
    if ! tmux switch-client -t "$session_name" 2>/dev/null; then
        log_error "Failed to switch client to session: $session_name"
        return 1
    fi

    return 0
}

# Function: process_result
# Description: Handle the fzf result
# Args:
#   $1 - fzf result
# Returns:
#   0 - success
#   1 - error
process_result() {
    local result="$1"

    if [[ -z "$result" ]]; then
        log_debug "No selection made"
        return 0
    fi

    log_debug "Result: $result"

    # Via become: "switch-window <session> <window_index>"
    if [[ "$result" =~ ^switch-window ]]; then
        local session_name window_index
        session_name=$(echo "$result" | awk '{print $2}')
        window_index=$(echo "$result" | awk '{print $3}')
        switch_to_window "$session_name" "$window_index"
    else
        log_debug "Unknown result: $result"
    fi
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Entry point for window selection mode
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
main() {
    local session_name="${1:-}"

    if [[ -z "$session_name" ]]; then
        echo "Usage: $0 <session_name>"
        return 1
    fi

    log_info "Starting detail-mode for session: $session_name"

    local window_list
    if ! window_list=$(bash "${CURRENT_DIR}/window-list.sh" "$session_name"); then
        log_error "Failed to generate window list"
        echo "Error: Failed to get window list"
        return 1
    fi

    local fzf_options
    fzf_options=$(build_fzf_options "$session_name")

    log_debug "fzf options: $fzf_options"

    local result
    result=$(echo "$window_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    process_result "$result"

    log_info "detail-mode finished"
    return 0
}

main "$@"
