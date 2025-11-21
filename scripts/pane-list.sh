#!/usr/bin/env bash
# ファイル名: pane-list.sh
# 説明: ペーン一覧生成
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

# 関数名: get_panes
# 説明: ペーン情報を取得
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: ペーン情報（パイプ区切り）
get_panes() {
    local session_name="$1"
    local window_index="$2"

    tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_active}" \
        2>/dev/null || {
        log_error "Failed to get panes for window: $session_name:$window_index"
        return 1
    }
}

# 関数名: get_command_icon
# 説明: コマンドに応じたアイコンを取得
# 引数:
#   $1 - コマンド名
# 戻り値: 0
# 出力: アイコン
get_command_icon() {
    local cmd="$1"

    case "$cmd" in
        vim|nvim) echo "📝" ;;
        bash|zsh|fish) echo "🐚" ;;
        ssh) echo "🔐" ;;
        python*) echo "🐍" ;;
        node|npm) echo "📦" ;;
        docker) echo "🐳" ;;
        *) echo "⚙️ " ;;
    esac
}

# 関数名: format_pane_line
# 説明: 1ペーンの行をフォーマット
# 引数:
#   $1 - index
#   $2 - command
#   $3 - width
#   $4 - height
#   $5 - active
# 戻り値: 0
# 出力: フォーマット済み行
format_pane_line() {
    local index="$1"
    local cmd="$2"
    local width="$3"
    local height="$4"
    local active="$5"

    # アクティブマーカー
    local marker color
    if [[ "$active" == "1" ]]; then
        marker="❯"
        color="\033[1;32m"
    else
        marker=" "
        color="\033[0m"
    fi

    # コマンドアイコン
    local icon
    icon=$(get_command_icon "$cmd")

    # コマンド名を切り詰め
    local display_cmd
    display_cmd=$(truncate_string "$cmd" 15)
    display_cmd=$(printf "%-15s" "$display_cmd")

    # 出力形式: "<index>\t<表示文字列>"
    printf "%s\t%b%s %s %s \033[2m(%dx%d)\033[0m\n" \
        "$index" "$color" "$marker" "$icon" "$display_cmd" "$width" "$height"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ペーン一覧を生成して標準出力
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    local session_name="${1:-}"
    local window_index="${2:-}"

    if [[ -z "$session_name" ]] || [[ -z "$window_index" ]]; then
        echo "Usage: $0 <session_name> <window_index>"
        return 1
    fi

    log_debug "Generating pane list for window: $session_name:$window_index"

    # ペーン一覧取得
    local panes
    if ! panes=$(get_panes "$session_name" "$window_index"); then
        log_error "Failed to get panes"
        echo "No panes available"
        return 1
    fi

    # フォーマット
    echo "$panes" | while IFS='|' read -r index cmd width height active; do
        format_pane_line "$index" "$cmd" "$width" "$height" "$active"
    done

    log_debug "Pane list generated successfully"
    return 0
}

main "$@"
