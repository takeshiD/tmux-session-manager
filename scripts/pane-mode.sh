#!/usr/bin/env bash
# File: pane-mode.sh
# Description: Pane selection mode
# Dependencies: config.sh, utils.sh, pane-list.sh, preview-pane.sh

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
#   $2 - windowindex
# Returns: 0
# Output: fzf option string
build_fzf_options() {
    local session_name="$1"
    local window_index="$2"
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    local header="Pane ${session_name}:${window_index} | ⏎ switch | ESC back | C-/ preview"
    local prompt="🖼️  Panes > "

    echo "$base_options \
        --delimiter='\t' \
        --with-nth=2 \
        --header='$header' \
        --prompt='$prompt' \
        --preview='bash ${CURRENT_DIR}/preview-pane.sh ${session_name} ${window_index} {1}' \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch-pane ${session_name} ${window_index} {1})' \
        --bind='ctrl-/:toggle-preview' \
        --bind='esc:abort' \
        --bind='q:abort'"
}

# Function: switch_to_pane
# Description: Switch to the specified pane
# Args:
#   $1 - session name
#   $2 - windowindex
#   $3 - paneindex
# Returns:
#   0 - success
#   1 - error
switch_to_pane() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    log_info "Switching to pane: $session_name:$window_index.$pane_index"

    if ! tmux select-pane -t "${session_name}:${window_index}.${pane_index}" 2>/dev/null; then
        log_error "Failed to select pane"
        tmux display-message "Error: Failed to switch to pane"
        return 1
    fi

    # Ensure the window is selected too
    if ! tmux select-window -t "${session_name}:${window_index}" 2>/dev/null; then
        log_error "Failed to select window"
        return 1
    fi

    # Then switch the client to the session
    if ! tmux switch-client -t "$session_name" 2>/dev/null; then
        log_error "Failed to switch client to session"
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

    # Via become: "switch-pane <session> <window_index> <pane_index>"
    if [[ "$result" =~ ^switch-pane ]]; then
        local session_name window_index pane_index
        session_name=$(echo "$result" | awk '{print $2}')
        window_index=$(echo "$result" | awk '{print $3}')
        pane_index=$(echo "$result" | awk '{print $4}')
        switch_to_pane "$session_name" "$window_index" "$pane_index"
    fi
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Entry point for pane selection mode
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

    log_info "Starting pane-mode for window: $session_name:$window_index"

    local pane_list
    if ! pane_list=$(bash "${CURRENT_DIR}/pane-list.sh" "$session_name" "$window_index"); then
        log_error "Failed to generate pane list"
        echo "Error: Failed to get pane list"
        return 1
    fi

    local fzf_options
    fzf_options=$(build_fzf_options "$session_name" "$window_index")

    log_debug "fzf options: $fzf_options"

    local result
    result=$(echo "$pane_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    process_result "$result"

    log_info "pane-mode finished"
    return 0
}

main "$@"
