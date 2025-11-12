#!/usr/bin/env bash
# ファイル名: preview-pane.sh
# 説明: ペーンプレビュー生成
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
readonly PREVIEW_LINES=50

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: print_header
# 説明: ヘッダーボックスを生成
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーンindex
# 戻り値: 0
# 出力: ヘッダーボックス
print_header() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    local title="${session_name}:${window_index}.${pane_index}"

    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m🖼️  Pane: ${title}\033[0m"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# 関数名: get_pane_info
# 説明: ペーン基本情報を取得
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーンindex
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: ペーン情報（パイプ区切り）
get_pane_info() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    local info
    info=$(tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_current_path}|#{pane_pid}" \
        2>/dev/null | grep "^${pane_index}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Pane not found: $session_name:$window_index.$pane_index"
        return 1
    fi

    echo "$info"
}

# 関数名: print_pane_info
# 説明: ペーン情報を表示
# 引数:
#   $1 - command
#   $2 - width
#   $3 - height
#   $4 - path
#   $5 - pid
# 戻り値: 0
# 出力: フォーマット済みペーン情報
print_pane_info() {
    local cmd="$1"
    local width="$2"
    local height="$3"
    local path="$4"
    local pid="$5"

    echo -e "\033[1;34m┌─ Info\033[0m"
    echo -e "\033[1;34m├─\033[0m Command:      \033[1;33m${cmd}\033[0m"
    echo -e "\033[1;34m├─\033[0m Size:         \033[1;32m${width}x${height}\033[0m"
    echo -e "\033[1;34m├─\033[0m Path:         \033[2m${path}\033[0m"
    echo -e "\033[1;34m└─\033[0m PID:          \033[2m${pid}\033[0m"
    echo
}

# 関数名: print_pane_content
# 説明: ペーン内容を表示
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーンindex
# 戻り値: 0
# 出力: ペーン内容
print_pane_content() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    echo -e "\033[1;34m┌─ Content (last ${PREVIEW_LINES} lines)\033[0m"

    if ! tmux capture-pane -t "${session_name}:${window_index}.${pane_index}" -p -S - 2>/dev/null | \
        tail -${PREVIEW_LINES} | \
        while IFS= read -r line; do
            echo -e "\033[1;34m│\033[0m $line"
        done; then
        echo -e "\033[1;34m│\033[0m \033[2m(Content not available)\033[0m"
    fi

    echo -e "\033[1;34m└─\033[0m"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ペーンプレビューを生成
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーンindex
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    local session_name="${1:-}"
    local window_index="${2:-}"
    local pane_index="${3:-}"

    if [[ -z "$session_name" ]] || [[ -z "$window_index" ]] || [[ -z "$pane_index" ]]; then
        echo "Usage: $0 <session_name> <window_index> <pane_index>"
        return 1
    fi

    log_debug "Generating preview for pane: $session_name:$window_index.$pane_index"

    # ペーン情報取得
    local info
    if ! info=$(get_pane_info "$session_name" "$window_index" "$pane_index"); then
        echo "Error: Pane not found"
        return 1
    fi

    # パース
    IFS='|' read -r idx cmd width height path pid <<< "$info"

    # 描画
    print_header "$session_name" "$window_index" "$idx"
    print_pane_info "$cmd" "$width" "$height" "$path" "$pid"
    print_pane_content "$session_name" "$window_index" "$idx"

    log_debug "Preview generated successfully"
    return 0
}

main "$@"
