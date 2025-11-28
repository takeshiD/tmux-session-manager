#!/usr/bin/env bash
# File: switcher.sh
# Description: Main entry point
# Dependencies: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# Load config
# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"

# Load utilities
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# Main
# ====================================================================

# Function: main
# Description: Plugin entry point
# Args: none
# Returns:
#   0 - success
#   1 - error
main() {
    log_info "Starting tmux-session-manager"

    if ! check_dependencies; then
        log_error "Dependency check failed"
        tmux display-message "Error: Dependencies not met. Check log at ${LOG_FILE}"
        return 1
    fi

    log_debug "Launching popup: ${POPUP_WIDTH}x${POPUP_HEIGHT}"

    local popup_border_flag=()
    case "${POPUP_BORDER,,}" in
        0|false|off|none|disable|disabled|no)
            popup_border_flag+=(-B)
            ;;
    esac

    if ! tmux display-popup \
        "${popup_border_flag[@]}" \
        -E \
        -w "$POPUP_WIDTH" \
        -h "$POPUP_HEIGHT" \
        "bash '${CURRENT_DIR}/session-mode.sh'"; then

        log_error "Failed to launch popup"

        # Fallback: open a normal window
        log_warn "Falling back to normal window"
        tmux new-window "bash '${CURRENT_DIR}/session-mode.sh'"
    fi

    log_info "tmux-session-manager finished"
    return 0
}

main "$@"
