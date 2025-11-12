#!/usr/bin/env bash
# ファイル名: window-list.sh
# 説明: ウィンドウ一覧生成
# 依存: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: get_windows
# 説明: ウィンドウ情報を取得
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: ウィンドウ情報（パイプ区切り）
get_windows() {
    local session_name="$1"

    tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}|#{window_active}" \
        2>/dev/null || {
        log_error "Failed to get windows for session: $session_name"
        return 1
    }
}

# 関数名: get_layout_icon
# 説明: ペーン数に応じたレイアウトアイコンを取得
# 引数:
#   $1 - ペーン数
# 戻り値: 0
# 出力: レイアウトアイコン
get_layout_icon() {
    local panes="$1"

    if [[ $panes -eq 1 ]]; then
        echo "▢"  # 単一ペーン
    else
        echo "⊞"  # 複数ペーン
    fi
}

# 関数名: format_window_line
# 説明: 1ウィンドウの行をフォーマット
# 引数:
#   $1 - index
#   $2 - name
#   $3 - panes
#   $4 - active
# 戻り値: 0
# 出力: フォーマット済み行
format_window_line() {
    local index="$1"
    local name="$2"
    local panes="$3"
    local active="$4"

    # アクティブマーカー
    local marker color
    if [[ "$active" == "1" ]]; then
        marker="❯"
        color="\033[1;32m"
    else
        marker=" "
        color="\033[0m"
    fi

    # レイアウトアイコン
    local layout_icon
    layout_icon=$(get_layout_icon "$panes")

    # ウィンドウ名を切り詰め
    local display_name
    display_name=$(truncate_string "$name" 25)
    display_name=$(printf "%-25s" "$display_name")

    # フォーマット出力
    printf "%b%s %2d: %s %s \033[2m[%dP]\033[0m\n" \
        "$color" "$marker" "$index" "$display_name" "$layout_icon" "$panes"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ウィンドウ一覧を生成して標準出力
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    local session_name="${1:-}"

    if [[ -z "$session_name" ]]; then
        echo "Usage: $0 <session_name>"
        return 1
    fi

    log_debug "Generating window list for session: $session_name"

    # ウィンドウ一覧取得
    local windows
    if ! windows=$(get_windows "$session_name"); then
        log_error "Failed to get windows"
        echo "No windows available"
        return 1
    fi

    # フォーマット
    echo "$windows" | while IFS='|' read -r index name panes active; do
        format_window_line "$index" "$name" "$panes" "$active"
    done

    log_debug "Window list generated successfully"
    return 0
}

main "$@"
