#!/usr/bin/env bash
# ファイル名: pane-mode.sh
# 説明: ペーン選択モード
# 依存: config.sh, utils.sh, pane-list.sh, preview-pane.sh

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

# 関数名: build_fzf_options
# 説明: fzfオプションを構築
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
# 戻り値: 0
# 出力: fzfオプション文字列
build_fzf_options() {
    local session_name="$1"
    local window_index="$2"
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    local header="┃ Window: ${session_name}:${window_index} │ ⏎ Switch │ ESC Back │ Ctrl-/ Preview ┃"
    local prompt="🖼️  Panes > "

    echo "$base_options \
        --header='$header' \
        --prompt='$prompt' \
        --preview='bash ${CURRENT_DIR}/preview-pane.sh ${session_name} ${window_index} {1}' \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch-pane ${session_name} ${window_index} {1})' \
        --bind='ctrl-/:toggle-preview' \
        --bind='esc:abort' \
        --bind='q:abort'"
}

# 関数名: switch_to_pane
# 説明: ペーン切り替えを実行
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
#   $3 - ペーンindex
# 戻り値:
#   0 - 成功
#   1 - エラー
switch_to_pane() {
    local session_name="$1"
    local window_index="$2"
    local pane_index="$3"

    log_info "Switching to pane: $session_name:$window_index.$pane_index"

    if ! tmux select-pane -t "${session_name}:${window_index}.${pane_index}" 2>/dev/null; then
        log_error "Failed to select pane"
        tmux display-message "Error: Failed to switch to pane"
        return 1
    fi

    # ウィンドウも選択
    if ! tmux select-window -t "${session_name}:${window_index}" 2>/dev/null; then
        log_error "Failed to select window"
        return 1
    fi

    # セッションに切り替え
    if ! tmux switch-client -t "$session_name" 2>/dev/null; then
        log_error "Failed to switch client to session"
        return 1
    fi

    return 0
}

# 関数名: process_result
# 説明: fzf結果を処理
# 引数:
#   $1 - fzf結果
# 戻り値:
#   0 - 成功
#   1 - エラー
process_result() {
    local result="$1"

    if [[ -z "$result" ]]; then
        log_debug "No selection made"
        return 0
    fi

    log_debug "Result: $result"

    # become経由の場合、"switch-pane セッション名 ウィンドウindex ペーンindex" の形式
    if [[ "$result" =~ ^switch-pane ]]; then
        local session_name window_index pane_index
        session_name=$(echo "$result" | awk '{print $2}')
        window_index=$(echo "$result" | awk '{print $3}')
        pane_index=$(echo "$result" | awk '{print $4}')
        switch_to_pane "$session_name" "$window_index" "$pane_index"
    fi
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ペーン選択モードのメイン処理
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

    log_info "Starting pane-mode for window: $session_name:$window_index"

    # ペーン一覧生成
    local pane_list
    if ! pane_list=$(bash "${CURRENT_DIR}/pane-list.sh" "$session_name" "$window_index"); then
        log_error "Failed to generate pane list"
        echo "Error: Failed to get pane list"
        return 1
    fi

    # fzfオプション構築
    local fzf_options
    fzf_options=$(build_fzf_options "$session_name" "$window_index")

    log_debug "fzf options: $fzf_options"

    # fzf起動
    local result
    result=$(echo "$pane_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    # 結果処理
    process_result "$result"

    log_info "pane-mode finished"
    return 0
}

main "$@"
