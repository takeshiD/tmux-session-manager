#!/usr/bin/env bash
# File: actions.sh
# Description: CRUD actions (create / delete / rename sessions)
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

# Function: action_new
# Description: Create a new session
# Args: none (reads name from fzf)
# Returns:
#   0 - success
#   1 - error
action_new() {
    log_info "Creating new session"
    local fzf_out fzf_status new_name
    set +o pipefail
    exist_sessions=$(tmux list-sessions -F "#S")
    fzf_out=$(echo "$exist_sessions" | fzf \
        --print-query \
        --phony \
        --prompt="Create new session: " \
        --header="Exist Sessions" \
        --border=rounded)
    fzf_status=${PIPESTATUS[0]}
    set -o pipefail

    # --print-query returns query on first line, selection on second; grab the query
    new_name=$(printf '%s' "$fzf_out" | head -n1)
    log_info "New session name: $new_name"
    # fzf aborted
    if [[ $fzf_status -ne 0 ]]; then
        log_error "fzf aborted for new session name"
        return 1
    fi

    # Cancel when empty input
    if [[ -z "$new_name" ]]; then
        log_info "New session creation cancelled"
        return 0
    fi

    if ! validate_session_name "$new_name"; then
        tmux display-message "Error: Invalid session name"
        return 1
    fi

    # Duplication check
    if tmux has-session -t "$new_name" 2>/dev/null; then
        log_error "Session already exists: $new_name"
        tmux display-message "Error: Session '$new_name' already exists"
        return 1
    fi

    # Create session
    if tmux new-session -d -s "$new_name"; then
        log_info "Created session: $new_name"
        tmux display-message "Created session '$new_name'"
        return 0
    else
        log_error "Failed to create session: $new_name"
        tmux display-message "Error: Failed to create session '$new_name'"
        return 1
    fi
}

# Function: action_rename
# Description: Rename a session
# Args:
#   $1 - currentsession name
# Returns:
#   0 - success
#   1 - error
action_rename() {
    local session_name="$1"

    log_info "Renaming session: $session_name"

    # Prompt for new name (prefill current)
    local fzf_out fzf_status new_name
    set +o pipefail
    exist_sessions=$(tmux list-sessions -F "#S")
    fzf_out=$(echo "$exist_sessions" | fzf \
        --print-query \
        --phony \
        --prompt="Rename session for '$session_name': " \
        --header="Exist Sessions" \
        --border=rounded)
    fzf_status=${PIPESTATUS[0]}
    set -o pipefail

    # First line from --print-query is latest user input
    new_name=$(printf '%s' "$fzf_out" | head -n1)

    if [[ $fzf_status -ne 0 ]]; then
        log_error "fzf aborted for rename"
        return 1
    fi

    # Cancel when empty input
    if [[ -z "$new_name" ]]; then
        log_info "Rename cancelled"
        return 0
    fi

    # No change
    if [[ "$new_name" == "$session_name" ]]; then
        log_info "No change in session name"
        return 0
    fi

    if ! validate_session_name "$new_name"; then
        tmux display-message "Error: Invalid session name"
        return 1
    fi

    # Duplication check
    if tmux has-session -t "$new_name" 2>/dev/null; then
        log_error "Session already exists: $new_name"
        tmux display-message "Error: Session '$new_name' already exists"
        return 1
    fi

    # Perform rename
    if tmux rename-session -t "$session_name" "$new_name"; then
        log_info "Renamed session: $session_name -> $new_name"
        tmux display-message "Renamed session '$session_name' to '$new_name'"
        return 0
    else
        log_error "Failed to rename session: $session_name"
        tmux display-message "Error: Failed to rename session '$session_name'"
        return 1
    fi
}

# Function: action_kill
# Description: Delete a session
# Args:
#   $1 - session name
# Returns:
#   0 - success
#   1 - error
action_kill() {
    local session_name="$1"

    log_info "Attempting to kill session: $session_name"

    # Confirmation prompt
    local confirm
    confirm=$(echo -e "No\nYes" | fzf \
        --prompt="Kill session '$session_name'? " \
        --header="WARNING: This cannot be undone!" \
        --height=5 \
        --border=rounded)

    # Cancel when anything but Yes
    if [[ "$confirm" != "Yes" ]]; then
        log_info "Kill session cancelled"
        return 0
    fi

    # Do not allow deleting the last session
    local session_count
    session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    if [[ $session_count -eq 1 ]]; then
        log_error "Cannot kill the last session"
        tmux display-message "Error: Cannot kill the last session"
        return 1
    fi

    # If killing the current session, switch first
    local current_session
    current_session=$(tmux display-message -p '#S' 2>/dev/null)

    if [[ "$session_name" == "$current_session" ]]; then
        log_debug "Killing current session, switching to another first"

        local other_session
        other_session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | \
            grep -v "^${session_name}$" | head -1)

        if [[ -z "$other_session" ]]; then
            log_error "No other session to switch to"
            tmux display-message "Error: No other session available"
            return 1
        fi

        tmux switch-client -t "$other_session"
    fi

    # Delete session
    if tmux kill-session -t "$session_name"; then
        log_info "Killed session: $session_name"
        tmux display-message "Killed session '$session_name'"
        return 0
    else
        log_error "Failed to kill session: $session_name"
        tmux display-message "Error: Failed to kill session '$session_name'"
        return 1
    fi
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Action dispatcher
# Args:
#   $1 - action (new/rename/kill)
#   $2 - session name (required for rename/kill)
# Returns:
#   0 - success
#   1 - error
main() {
    local action="${1:-}"
    local session_name="${2:-}"

    log_debug "Action: $action, Session: $session_name"

    case "$action" in
        new)
            action_new
            ;;
        rename)
            if [[ -z "$session_name" ]]; then
                log_error "Session name required for rename action"
                return 1
            fi
            action_rename "$session_name"
            ;;
        kill)
            if [[ -z "$session_name" ]]; then
                log_error "Session name required for kill action"
                return 1
            fi
            action_kill "$session_name"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Usage: $0 {new|rename|kill} [session_name]"
            return 1
            ;;
    esac
}

main "$@"
