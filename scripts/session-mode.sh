#!/usr/bin/env bash
# File: session-mode.sh
# Description: Session selection mode
# Dependencies: config.sh, utils.sh, session-list.sh, preview-session.sh

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

# Keep the header short so it fits typical terminal widths (~80 chars)
readonly HEADER="⏎ switch | ␣ detail | C-n new | C-r rename | C-x kill | C-/ preview | q quit"
readonly PROMPT="🔍 Sessions > "

# ====================================================================
# Function definitions
# ====================================================================

# Function: build_fzf_options
# Description: Build fzf options
# Args: none
# Returns: 0
# Output: fzf option string
build_fzf_options() {
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    # Key bindings
    echo "$base_options \
        --header='$HEADER' \
        --prompt='$PROMPT' \
        --preview=\"PREVIEW_REFRESH_MS=${PREVIEW_REFRESH_MS} bash ${CURRENT_DIR}/preview-session.sh {1}\" \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch {1})' \
        --bind='space:execute(bash ${CURRENT_DIR}/detail-mode.sh {1})' \
        --bind='ctrl-n:execute(bash ${CURRENT_DIR}/actions.sh new)+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-r:execute(bash ${CURRENT_DIR}/actions.sh rename {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-x:execute(bash ${CURRENT_DIR}/actions.sh kill {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-l:refresh-preview' \
        --bind='ctrl-/:toggle-preview' \
        --bind='q:abort'"
}

# Function: switch_to_session
# Description: Switch to the given session
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
switch_to_session() {
    local session_name="$1"

    log_info "Switching to session: $session_name"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        log_error "Session does not exist: $session_name"
        tmux display-message "Error: Session '$session_name' not found"
        return 1
    fi

    tmux switch-client -t "$session_name"
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

    # No-op when empty result (escape)
    if [[ -z "$result" ]]; then
        log_debug "No selection made"
        return 0
    fi

    log_debug "Result: $result"

    # When invoked via become the result format is "switch <session>"
    if [[ "$result" =~ ^switch ]]; then
        local session_name
        session_name=$(echo "$result" | awk '{print $2}')
        switch_to_session "$session_name"
    else
        # Plain enter returns just the session name
        local session_name
        session_name=$(echo "$result" | awk '{print $1}')
        switch_to_session "$session_name"
    fi
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Entry point for session selection mode
# Args: none
# Returns:
#   0 - success
#   1 - error
main() {
    log_info "Starting session-mode"

    local session_list
    if ! session_list=$(bash "${CURRENT_DIR}/session-list.sh"); then
        log_error "Failed to generate session list"
        echo "Error: Failed to get session list"
        return 1
    fi

    local fzf_options
    fzf_options=$(build_fzf_options)

    log_debug "fzf options: $fzf_options"

    local result
    result=$(echo "$session_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    process_result "$result"

    log_info "session-mode finished"
    return 0
}

main "$@"
