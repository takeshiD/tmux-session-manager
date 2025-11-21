#!/usr/bin/env bash
# ファイル名: actions.sh
# 説明: CRUD操作（セッション作成・削除・リネーム）
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

# 関数名: action_new
# 説明: 新規セッション作成
# 引数: なし（標準入力から名前を読み取る）
# 戻り値:
#   0 - 成功
#   1 - エラー
action_new() {
    log_info "Creating new session"

    # fzfを使って名前入力（stdinはダミー行、端末は/dev/tty）
    local new_name fzf_status
    set +o pipefail
    new_name=$(printf "\n" | fzf \
        --print-query \
        --prompt="New session name: " \
        --header="Enter name for new session" \
        --height=5 \
        --border=rounded </dev/tty)
    fzf_status=$?
    set -o pipefail

    # fzf起動に失敗した場合
    if [[ $fzf_status -ne 0 ]]; then
        log_error "fzf aborted for new session name"
        return 1
    fi

    # キャンセルチェック（空入力）
    if [[ -z "$new_name" ]]; then
        log_info "New session creation cancelled"
        return 0
    fi

    # バリデーション
    if ! validate_session_name "$new_name"; then
        tmux display-message "Error: Invalid session name"
        return 1
    fi

    # 重複チェック
    if tmux has-session -t "$new_name" 2>/dev/null; then
        log_error "Session already exists: $new_name"
        tmux display-message "Error: Session '$new_name' already exists"
        return 1
    fi

    # セッション作成
    if tmux new-session -d -s "$new_name"; then
        log_info "Created session: $new_name"
        tmux display-message "Created session '$new_name'"
        return 0
    else
        log_error "Failed to create session: $new_name"
        tmux display-message "Error: Failed to create session '$new_name'"
        return 1
    fi
}

# 関数名: action_rename
# 説明: セッション名変更
# 引数:
#   $1 - 現在のセッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
action_rename() {
    local session_name="$1"

    log_info "Renaming session: $session_name"

    # 新しい名前入力（初期値は現在の名前）
    local new_name fzf_status
    set +o pipefail
    new_name=$(echo "$session_name" | fzf \
        --print-query \
        --prompt="Rename session: " \
        --header="Enter new name for '$session_name'" \
        --height=5 \
        --border=rounded </dev/tty)
    fzf_status=$?
    set -o pipefail

    if [[ $fzf_status -ne 0 ]]; then
        log_error "fzf aborted for rename"
        return 1
    fi

    # キャンセルチェック
    if [[ -z "$new_name" ]]; then
        log_info "Rename cancelled"
        return 0
    fi

    # 変更なしチェック
    if [[ "$new_name" == "$session_name" ]]; then
        log_info "No change in session name"
        return 0
    fi

    # バリデーション
    if ! validate_session_name "$new_name"; then
        tmux display-message "Error: Invalid session name"
        return 1
    fi

    # 重複チェック
    if tmux has-session -t "$new_name" 2>/dev/null; then
        log_error "Session already exists: $new_name"
        tmux display-message "Error: Session '$new_name' already exists"
        return 1
    fi

    # リネーム実行
    if tmux rename-session -t "$session_name" "$new_name"; then
        log_info "Renamed session: $session_name -> $new_name"
        tmux display-message "Renamed session '$session_name' to '$new_name'"
        return 0
    else
        log_error "Failed to rename session: $session_name"
        tmux display-message "Error: Failed to rename session '$session_name'"
        return 1
    fi
}

# 関数名: action_kill
# 説明: セッション削除
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 成功
#   1 - エラー
action_kill() {
    local session_name="$1"

    log_info "Attempting to kill session: $session_name"

    # 確認プロンプト
    local confirm
    confirm=$(echo -e "No\nYes" | fzf \
        --prompt="Kill session '$session_name'? " \
        --header="WARNING: This cannot be undone!" \
        --height=5 \
        --border=rounded)

    # キャンセルまたはNo選択
    if [[ "$confirm" != "Yes" ]]; then
        log_info "Kill session cancelled"
        return 0
    fi

    # 最後のセッションチェック
    local session_count
    session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    if [[ $session_count -eq 1 ]]; then
        log_error "Cannot kill the last session"
        tmux display-message "Error: Cannot kill the last session"
        return 1
    fi

    # 現在のセッションかどうか確認
    local current_session
    current_session=$(tmux display-message -p '#S' 2>/dev/null)

    if [[ "$session_name" == "$current_session" ]]; then
        # 現在のセッションの場合は別のセッションに切り替えてから削除
        log_debug "Killing current session, switching to another first"

        local other_session
        other_session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | \
            grep -v "^${session_name}$" | head -1)

        if [[ -z "$other_session" ]]; then
            log_error "No other session to switch to"
            tmux display-message "Error: No other session available"
            return 1
        fi

        # 別のセッションに切り替え
        tmux switch-client -t "$other_session"
    fi

    # セッション削除
    if tmux kill-session -t "$session_name"; then
        log_info "Killed session: $session_name"
        tmux display-message "Killed session '$session_name'"
        return 0
    else
        log_error "Failed to kill session: $session_name"
        tmux display-message "Error: Failed to kill session '$session_name'"
        return 1
    fi
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: アクションのディスパッチャ
# 引数:
#   $1 - アクション (new/rename/kill)
#   $2 - セッション名（renameとkillで必要）
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    local action="${1:-}"
    local session_name="${2:-}"

    log_debug "Action: $action, Session: $session_name"

    case "$action" in
        new)
            action_new
            ;;
        rename)
            if [[ -z "$session_name" ]]; then
                log_error "Session name required for rename action"
                return 1
            fi
            action_rename "$session_name"
            ;;
        kill)
            if [[ -z "$session_name" ]]; then
                log_error "Session name required for kill action"
                return 1
            fi
            action_kill "$session_name"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Usage: $0 {new|rename|kill} [session_name]"
            return 1
            ;;
    esac
}

main "$@"
