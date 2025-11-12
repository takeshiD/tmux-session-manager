#!/usr/bin/env bash
# ファイル名: preview-session.sh
# 説明: セッションプレビュー生成
# 依存: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# 定数
# ====================================================================

readonly BOX_WIDTH=60
readonly PREVIEW_LINES=15

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: print_header
# 説明: ヘッダーボックスを生成
# 引数:
#   $1 - セッション名
# 戻り値: 0
# 出力: ヘッダーボックス
print_header() {
    local session_name="$1"
    local name_display
    name_display=$(truncate_string "$session_name" $((BOX_WIDTH - 15)))

    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m📦 Session: ${name_display}\033[0m"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# 関数名: get_session_info
# 説明: セッション基本情報を取得
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: セッション情報（パイプ区切り）
get_session_info() {
    local session_name="$1"

    local info
    info=$(tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_windows}|#{session_created}|#{session_activity}" 2>/dev/null | \
        grep "^${session_name}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Session not found: $session_name"
        return 1
    fi

    echo "$info"
}

# 関数名: print_session_info
# 説明: セッション情報を表示
# 引数:
#   $1 - session_name
#   $2 - attached
#   $3 - windows
#   $4 - created
#   $5 - activity
# 戻り値: 0
# 出力: フォーマット済みセッション情報
print_session_info() {
    local session_name="$1"
    local attached="$2"
    local windows="$3"
    local created="$4"
    local activity="$5"

    local status
    [[ $attached -gt 0 ]] && status="attached" || status="detached"

    local created_ago
    created_ago=$(format_time_ago "$created")

    local activity_ago
    activity_ago=$(format_time_ago "$activity")

    echo -e "\033[1;34m┌─ Info\033[0m"
    echo -e "\033[1;34m├─\033[0m Status:       \033[1;33m${status}\033[0m"
    echo -e "\033[1;34m├─\033[0m Windows:      \033[1;32m${windows}\033[0m"
    echo -e "\033[1;34m├─\033[0m Created:      \033[2m${created_ago} ago\033[0m"
    echo -e "\033[1;34m└─\033[0m Last Activity: \033[2m${activity_ago} ago\033[0m"
    echo
}

# 関数名: get_windows
# 説明: ウィンドウ一覧を取得
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

# 関数名: print_windows
# 説明: ウィンドウ一覧を表示
# 引数:
#   $1 - セッション名
# 戻り値: 0
# 出力: フォーマット済みウィンドウ一覧
print_windows() {
    local session_name="$1"

    echo -e "\033[1;34m┌─ Windows\033[0m"

    local windows
    windows=$(get_windows "$session_name")

    echo "$windows" | while IFS='|' read -r idx name panes active; do
        local marker color
        if [[ "$active" == "1" ]]; then
            marker="❯"
            color="\033[1;32m"
        else
            marker="│"
            color="\033[2m"
        fi

        local display_name
        display_name=$(truncate_string "$name" 30)

        printf "%b%s %2d: %-30s \033[2m[%dP]\033[0m\n" \
            "$color" "$marker" "$idx" "$display_name" "$panes"
    done

    echo
}

# 関数名: print_active_pane_preview
# 説明: アクティブウィンドウのペーンプレビューを表示
# 引数:
#   $1 - セッション名
# 戻り値: 0
# 出力: ペーン内容プレビュー
print_active_pane_preview() {
    local session_name="$1"

    # アクティブウィンドウindex取得
    local active_window
    active_window=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_active}" 2>/dev/null | \
        grep "|1$" | cut -d'|' -f1 | head -1)

    if [[ -z "$active_window" ]]; then
        log_warn "No active window found"
        return 0
    fi

    # ウィンドウ名取得
    local window_name
    window_name=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}" 2>/dev/null | \
        grep "^${active_window}|" | cut -d'|' -f2)

    echo -e "\033[1;34m┌─ Active Window Preview: \033[1;36m${window_name}\033[0m"

    # ペーン内容キャプチャ
    if ! tmux capture-pane -t "${session_name}:${active_window}.0" -p 2>/dev/null | head -${PREVIEW_LINES} | \
        while IFS= read -r line; do
            echo -e "\033[1;34m│\033[0m   $line"
        done; then
        echo -e "\033[1;34m│\033[0m   \033[2m(Preview not available)\033[0m"
    fi

    echo -e "\033[1;34m└─\033[0m \033[2m(Showing first ${PREVIEW_LINES} lines of pane 0)\033[0m"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: セッションプレビューを生成
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    local session_name="$1"

    log_debug "Generating preview for session: $session_name"

    # セッション情報取得
    local info
    if ! info=$(get_session_info "$session_name"); then
        echo "Error: Session not found"
        return 1
    fi

    # パース
    IFS='|' read -r name attached windows created activity <<< "$info"

    # 描画
    print_header "$name"
    print_session_info "$name" "$attached" "$windows" "$created" "$activity"
    print_windows "$name"
    print_active_pane_preview "$name"

    log_debug "Preview generated successfully"
    return 0
}

# 引数チェック
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <session_name>"
    exit 1
fi

main "$@"
