#!/usr/bin/env bash
# ファイル名: detail-mode.sh
# 説明: ウィンドウ選択モード
# 依存: config.sh, utils.sh, window-list.sh, preview-window.sh

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
# 戻り値: 0
# 出力: fzfオプション文字列
build_fzf_options() {
    local session_name="$1"
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    # ヘッダーをコンパクトに（約80文字以内）
    local header="Session:${session_name} | ⏎ switch | ␣ panes | ESC back | C-/ preview"
    local prompt="🪟 Windows > "

    echo "$base_options \
        --delimiter='\t' \
        --with-nth=2 \
        --header='$header' \
        --prompt='$prompt' \
        --preview='bash ${CURRENT_DIR}/preview-window.sh ${session_name} {1}' \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch-window ${session_name} {1})' \
        --bind='space:execute(bash ${CURRENT_DIR}/pane-mode.sh ${session_name} {1})+abort' \
        --bind='ctrl-/:toggle-preview' \
        --bind='esc:abort' \
        --bind='q:abort'"
}

# 関数名: switch_to_window
# 説明: ウィンドウ切り替えを実行
# 引数:
#   $1 - セッション名
#   $2 - ウィンドウindex
# 戻り値:
#   0 - 成功
#   1 - エラー
switch_to_window() {
    local session_name="$1"
    local window_index="$2"

    log_info "Switching to window: $session_name:$window_index"

    if ! tmux select-window -t "${session_name}:${window_index}" 2>/dev/null; then
        log_error "Failed to select window: $session_name:$window_index"
        tmux display-message "Error: Failed to switch to window"
        return 1
    fi

    # セッションも切り替え
    if ! tmux switch-client -t "$session_name" 2>/dev/null; then
        log_error "Failed to switch client to session: $session_name"
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

    # become経由の場合、"switch-window セッション名 ウィンドウindex" の形式
    if [[ "$result" =~ ^switch-window ]]; then
        local session_name window_index
        session_name=$(echo "$result" | awk '{print $2}')
        window_index=$(echo "$result" | awk '{print $3}')
        switch_to_window "$session_name" "$window_index"
    else
        log_debug "Unknown result: $result"
    fi
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: ウィンドウ選択モードのメイン処理
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

    log_info "Starting detail-mode for session: $session_name"

    # ウィンドウ一覧生成
    local window_list
    if ! window_list=$(bash "${CURRENT_DIR}/window-list.sh" "$session_name"); then
        log_error "Failed to generate window list"
        echo "Error: Failed to get window list"
        return 1
    fi

    # fzfオプション構築
    local fzf_options
    fzf_options=$(build_fzf_options "$session_name")

    log_debug "fzf options: $fzf_options"

    # fzf起動
    local result
    result=$(echo "$window_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    # 結果処理
    process_result "$result"

    log_info "detail-mode finished"
    return 0
}

main "$@"
