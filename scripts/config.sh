#!/usr/bin/env bash
# File: config.sh
# Description: Configuration management for tmux-session-manager
# Dependencies: none

# ====================================================================
# Default settings
# ====================================================================

# Popup sizing
readonly DEFAULT_POPUP_WIDTH="70%"
readonly DEFAULT_POPUP_HEIGHT="70%"
readonly DEFAULT_PREVIEW_WIDTH="75"
readonly DEFAULT_PREVIEW_REFRESH_MS="200"

# Popup/border
readonly DEFAULT_POPUP_BORDER="on"
readonly DEFAULT_FZF_BORDER="none"

# Color theme
readonly DEFAULT_THEME="tokyonight"

# Key binding
readonly DEFAULT_KEY_BINDING="C-s"

# Logging
readonly DEFAULT_LOG_LEVEL="INFO"
readonly DEFAULT_LOG_FILE="/tmp/tmux-session-manager.log"

# ====================================================================
# Read settings from tmux.conf
# ====================================================================

# Function: get_tmux_option
# Description: Fetch option value from tmux.conf
# Args:
#   $1 - option name (without @ prefix)
#   $2 - default value
# Returns: 0
# Output: resolved option value or default
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value

    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

# ====================================================================
# Exported variables
# ====================================================================

# Popup settings
export POPUP_WIDTH=$(get_tmux_option "session-manager-popup-width" "$DEFAULT_POPUP_WIDTH")
export POPUP_HEIGHT=$(get_tmux_option "session-manager-popup-height" "$DEFAULT_POPUP_HEIGHT")
export PREVIEW_WIDTH=$(get_tmux_option "session-manager-preview-width" "$DEFAULT_PREVIEW_WIDTH")
export PREVIEW_REFRESH_MS=$(get_tmux_option "session-manager-preview-refresh-ms" "$DEFAULT_PREVIEW_REFRESH_MS")
export POPUP_BORDER=$(get_tmux_option "session-manager-popup-border" "$DEFAULT_POPUP_BORDER")
export FZF_BORDER_STYLE=$(get_tmux_option "session-manager-fzf-border" "$DEFAULT_FZF_BORDER")

# Theme
export THEME=$(get_tmux_option "session-manager-theme" "$DEFAULT_THEME")

# Logging
export LOG_LEVEL=$(get_tmux_option "session-manager-log-level" "$DEFAULT_LOG_LEVEL")
export LOG_FILE=$(get_tmux_option "session-manager-log-file" "$DEFAULT_LOG_FILE")

# Debug flag
export DEBUG_MODE=$(get_tmux_option "session-manager-debug" "0")

# ====================================================================
# fzf option builders
# ====================================================================

# Function: get_theme_colors
# Description: Return fzf color scheme for the given theme
# Args:
#   $1 - theme name
# Returns: 0
# Output: fzf color options string
get_theme_colors() {
    local theme="$1"

    case "$theme" in
        tokyonight)
            echo "--color=bg+:#364a82,bg:#1a1b26,border:#7aa2f7,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
            ;;
        catppuccin)
            echo "--color=bg+:#313244,bg:#1e1e2e,border:#89b4fa,fg:#cdd6f4,fg+:#cdd6f4,hl:#89b4fa,hl+:#94e2d5,info:#89b4fa,prompt:#94e2d5,pointer:#f38ba8,marker:#a6e3a1,spinner:#a6e3a1,header:#a6e3a1"
            ;;
        default)
            echo ""
            ;;
        *)
            # Warn and fall back to default when theme is unknown
            if command -v log_warn &> /dev/null; then
                log_warn "Unknown theme: $theme, using default"
            fi
            echo ""
            ;;
    esac
}

# Function: get_base_fzf_options
# Description: Build base fzf options
# Args: none
# Returns: 0
# Output: fzf base option string
get_base_fzf_options() {
    local theme_colors
    theme_colors=$(get_theme_colors "$THEME")
    local border_option

    case "${FZF_BORDER_STYLE,,}" in
        ""|none|0|false|off)
            border_option="--border=none"
            ;;
        *)
            border_option="--border=${FZF_BORDER_STYLE}"
            ;;
    esac

    echo "--ansi ${border_option} --height=100% $theme_colors"
}

# Function: get_preview_window_options
# Description: Build preview window options
# Args: none
# Returns: 0
# Output: preview window option string
get_preview_window_options() {
    echo "right:${PREVIEW_WIDTH}%:border-left"
}
