#!/usr/bin/env bash
# ファイル名: session-mode.sh
# 説明: セッション選択モード
# 依存: config.sh, utils.sh, session-list.sh, preview-session.sh

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

# ヘッダーは端末幅に収まるよう短く記載（約80文字）
readonly HEADER="⏎ switch | ␣ detail | C-n new | C-r rename | C-x kill | C-/ preview | q quit"
readonly PROMPT="🔍 Sessions > "

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: build_fzf_options
# 説明: fzfオプションを構築
# 引数: なし
# 戻り値: 0
# 出力: fzfオプション文字列
build_fzf_options() {
    local base_options preview_window

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    # キーバインド設定
    echo "$base_options \
        --header='$HEADER' \
        --prompt='$PROMPT' \
        --preview=\"PREVIEW_REFRESH_MS=${PREVIEW_REFRESH_MS} bash ${CURRENT_DIR}/preview-session.sh {1}\" \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch {1})' \
        --bind='space:execute(bash ${CURRENT_DIR}/detail-mode.sh {1})' \
        --bind='ctrl-n:execute(bash ${CURRENT_DIR}/actions.sh new)+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-r:execute(bash ${CURRENT_DIR}/actions.sh rename {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-x:execute(bash ${CURRENT_DIR}/actions.sh kill {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-l:refresh-preview' \
        --bind='ctrl-/:toggle-preview' \
        --bind='q:abort'"
}

# 関数名: switch_to_session
# 説明: セッション切り替えを実行
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
switch_to_session() {
    local session_name="$1"

    log_info "Switching to session: $session_name"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        log_error "Session does not exist: $session_name"
        tmux display-message "Error: Session '$session_name' not found"
        return 1
    fi

    tmux switch-client -t "$session_name"
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

    # 空の場合は何もしない
    if [[ -z "$result" ]]; then
        log_debug "No selection made"
        return 0
    fi

    log_debug "Result: $result"

    # become経由の場合、"switch セッション名" の形式
    if [[ "$result" =~ ^switch ]]; then
        local session_name
        session_name=$(echo "$result" | awk '{print $2}')
        switch_to_session "$session_name"
    else
        # 通常のEnter（セッション名のみ）
        local session_name
        session_name=$(echo "$result" | awk '{print $1}')
        switch_to_session "$session_name"
    fi
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: セッション選択モードのメイン処理
# 引数: なし
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    log_info "Starting session-mode"

    # セッション一覧生成
    local session_list
    if ! session_list=$(bash "${CURRENT_DIR}/session-list.sh"); then
        log_error "Failed to generate session list"
        echo "Error: Failed to get session list"
        return 1
    fi

    # fzfオプション構築
    local fzf_options
    fzf_options=$(build_fzf_options)

    log_debug "fzf options: $fzf_options"

    # fzf起動
    local result
    result=$(echo "$session_list" | eval "fzf $fzf_options") || {
        log_info "User cancelled selection"
        return 0
    }

    # 結果処理
    process_result "$result"

    log_info "session-mode finished"
    return 0
}

main "$@"
