#!/usr/bin/env bash
# File: tmux-session-manager.tmux
# Description: tmux plugin entry point
# Dependencies: none

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# ====================================================================
# Load settings
# ====================================================================

# Default key binding
readonly DEFAULT_KEY_BINDING="SPACE"

# Function: get_tmux_option
# Description: Fetch option from tmux.conf
# Args:
#   $1 - option name (without @ prefix)
#   $2 - default value
# Returns: resolved option value
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value
    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

KEY_BINDING=$(get_tmux_option "session-manager-key" "$DEFAULT_KEY_BINDING")

# ====================================================================
# Dependency check
# ====================================================================

# Function: check_dependencies
# Description: Verify required tools
# Args: none
# Returns:
#   0 - all good
#   1 - missing deps
check_dependencies() {
    local errors=0

    local tmux_version
    tmux_version=$(tmux -V | cut -d' ' -f2 | tr -d 'a-z')

    if ! awk -v ver="$tmux_version" 'BEGIN { exit (ver >= 3.2 ? 0 : 1) }'; then
        tmux display-message "Error: tmux 3.2 or higher required (found: $tmux_version)"
        errors=1
    fi

    if ! command -v fzf &> /dev/null; then
        tmux display-message "Error: fzf is not installed"
        errors=1
    fi

    if ! command -v bash &> /dev/null; then
        tmux display-message "Error: bash is not installed"
        errors=1
    fi

    return $errors
}

# ====================================================================
# Key binding registration
# ====================================================================

# Function: setup_keybindings
# Description: Define key bindings
# Args: none
# Returns: 0
setup_keybindings() {
    # Main key binding
    tmux bind-key "$KEY_BINDING" run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"

    # Optional prefix binding (example, commented out)
    # tmux bind-key s run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"
}

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Plugin initialization
# Args: none
# Returns:
#   0 - success
#   1 - failure
main() {
    if ! check_dependencies; then
        tmux display-message "tmux-session-manager: Dependency check failed"
        return 1
    fi

    setup_keybindings

    local debug_mode
    debug_mode=$(get_tmux_option "session-manager-debug" "0")
    if [[ "$debug_mode" == "1" ]]; then
        tmux display-message "tmux-session-manager loaded (key: $KEY_BINDING)"
    fi

    return 0
}

main
