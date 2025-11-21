#!/usr/bin/env bash
# ファイル名: config.sh
# 説明: 設定管理
# 依存: なし

# ====================================================================
# デフォルト設定
# ====================================================================

# ポップアップサイズ
readonly DEFAULT_POPUP_WIDTH="70%"
readonly DEFAULT_POPUP_HEIGHT="70%"
readonly DEFAULT_PREVIEW_WIDTH="55"

# ポップアップ/枠線
readonly DEFAULT_POPUP_BORDER="on"
readonly DEFAULT_FZF_BORDER="none"

# カラーテーマ
readonly DEFAULT_THEME="tokyonight"

# キーバインド
readonly DEFAULT_KEY_BINDING="C-s"

# ログ設定
readonly DEFAULT_LOG_LEVEL="INFO"
readonly DEFAULT_LOG_FILE="/tmp/tmux-session-manager.log"

# ====================================================================
# tmux.confから設定取得
# ====================================================================

# 関数名: get_tmux_option
# 説明: tmux.confからオプション値を取得
# 引数:
#   $1 - オプション名（@プレフィックスなし）
#   $2 - デフォルト値
# 戻り値: 0
# 出力: オプション値（設定されていればその値、なければデフォルト値）
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value

    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

# ====================================================================
# グローバル変数設定
# ====================================================================

# ポップアップ設定
export POPUP_WIDTH=$(get_tmux_option "session-manager-popup-width" "$DEFAULT_POPUP_WIDTH")
export POPUP_HEIGHT=$(get_tmux_option "session-manager-popup-height" "$DEFAULT_POPUP_HEIGHT")
export PREVIEW_WIDTH=$(get_tmux_option "session-manager-preview-width" "$DEFAULT_PREVIEW_WIDTH")
export POPUP_BORDER=$(get_tmux_option "session-manager-popup-border" "$DEFAULT_POPUP_BORDER")
export FZF_BORDER_STYLE=$(get_tmux_option "session-manager-fzf-border" "$DEFAULT_FZF_BORDER")

# テーマ設定
export THEME=$(get_tmux_option "session-manager-theme" "$DEFAULT_THEME")

# ログ設定
export LOG_LEVEL=$(get_tmux_option "session-manager-log-level" "$DEFAULT_LOG_LEVEL")
export LOG_FILE=$(get_tmux_option "session-manager-log-file" "$DEFAULT_LOG_FILE")

# デバッグモード
export DEBUG_MODE=$(get_tmux_option "session-manager-debug" "0")

# ====================================================================
# fzfオプション構築
# ====================================================================

# 関数名: get_theme_colors
# 説明: テーマに応じたfzfカラー設定を取得
# 引数:
#   $1 - テーマ名
# 戻り値: 0
# 出力: fzfカラー設定文字列
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
            # 不明なテーマの場合は警告してデフォルトを使用
            if command -v log_warn &> /dev/null; then
                log_warn "Unknown theme: $theme, using default"
            fi
            echo ""
            ;;
    esac
}

# 関数名: get_base_fzf_options
# 説明: 基本fzfオプションを構築
# 引数: なし
# 戻り値: 0
# 出力: fzf基本オプション文字列
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

# 関数名: get_preview_window_options
# 説明: プレビューウィンドウオプションを構築
# 引数: なし
# 戻り値: 0
# 出力: プレビューウィンドウオプション文字列
get_preview_window_options() {
    echo "right:${PREVIEW_WIDTH}%:wrap:border-left"
}
