#!/usr/bin/env bash
# ファイル名: preview-window.sh
# 説明: ウィンドウプレビュー生成
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
readonly PANE_PREVIEW_LINES=8

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: print_header
# 説明: ヘッダーボックスを生成
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ウィンドウ名
# 戻り値: 0
# 出力: ヘッダーボックス
print_header() {
    local session_name="$1"
    local window_index="$2"
    local window_name="$3"

    local title="${session_name}:${window_index} - ${window_name}"
    local title_display
    title_display=$(truncate_string "$title" $((BOX_WIDTH - 10)))

    local inner_width=$((BOX_WIDTH))
    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    printf "\033[1;35m║\033[0m \033[1;36m%-*s\033[0m\033[1;35m║\033[0m\n" \
        "$inner_width" "  Window: ${title_display}"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# 関数名: get_window_info
# 説明: ウィンドウ基本情報を取得
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: ウィンドウ情報（パイプ区切り）
get_window_info() {
    local session_name="$1"
    local window_index="$2"

    local info
    info=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}" 2>/dev/null | \
        grep "^${window_index}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Window not found: $session_name:$window_index"
        return 1
    fi

    echo "$info"
}

# 関数名: print_panes_list
# 説明: ペーン一覧を表示
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーン数
# 戻り値: 0
# 出力: ペーン一覧
print_panes_list() {
    local session_name="$1"
    local window_index="$2"
    local panes="$3"

    echo -e "\033[1;34m┌─ Panes (${panes})\033[0m"

    local panes_info
    panes_info=$(tmux list-panes -t "${session_name}:${window_index}" \
        -F "#{pane_index}|#{pane_current_command}|#{pane_width}|#{pane_height}|#{pane_active}" \
        2>/dev/null)

    echo "$panes_info" | while IFS='|' read -r idx cmd width height active; do
        local marker color
        if [[ "$active" == "1" ]]; then
            marker="❯"
            color="\033[1;32m"
        else
            marker="│"
            color="\033[2m"
        fi

        # コマンドアイコン
        local icon
        case "$cmd" in
            vim|nvim) icon="📝" ;;
            bash|zsh|fish) icon="🐚" ;;
            ssh) icon="🔐" ;;
            *) icon="⚙️ " ;;
        esac

        printf "%b%s %d: %s %-15s \033[2m(%dx%d)\033[0m\n" \
            "$color" "$marker" "$idx" "$icon" "$cmd" "$width" "$height"
    done

    echo
}

# 関数名: print_panes_preview
# 説明: 各ペインの内容プレビューを表示
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーン数
# 戻り値: 0
# 出力: ペーン内容プレビュー
print_panes_preview() {
    local session_name="$1"
    local window_index="$2"
    local panes="$3"

    for i in $(seq 0 $((panes - 1))); do
        local cmd
        cmd=$(tmux display-message -t "${session_name}:${window_index}.${i}" -p "#{pane_current_command}" 2>/dev/null)

        echo -e "\033[1;34m├─ Pane $i ($cmd):\033[0m"

        if ! tmux capture-pane -t "${session_name}:${window_index}.${i}" -e -p 2>/dev/null | \
            head -${PANE_PREVIEW_LINES} | \
            while IFS= read -r line; do
                echo -e "\033[1;34m│\033[0m   $line"
            done; then
            echo -e "\033[1;34m│\033[0m   \033[2m(Preview not available)\033[0m"
        fi
        echo
    done
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ウィンドウプレビューを生成
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

    log_debug "Generating preview for window: $session_name:$window_index"

    # ウィンドウ情報取得
    local info
    if ! info=$(get_window_info "$session_name" "$window_index"); then
        echo "Error: Window not found"
        return 1
    fi

    # パース
    IFS='|' read -r idx name panes <<< "$info"

    # 描画
    print_header "$session_name" "$idx" "$name"
    print_panes_list "$session_name" "$idx" "$panes"
    print_panes_preview "$session_name" "$idx" "$panes"

    log_debug "Preview generated successfully"
    return 0
}

main "$@"
