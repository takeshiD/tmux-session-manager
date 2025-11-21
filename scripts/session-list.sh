#!/usr/bin/env bash
# ファイル名: session-list.sh
# 説明: セッション一覧生成
# 依存: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# グローバル変数
# ====================================================================

CURRENT_SESSION=""

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: get_sessions
# 説明: セッション情報を取得
# 引数: なし
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: セッション情報（パイプ区切り）
get_sessions() {
    tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}|#{session_activity}" 2>/dev/null || {
        log_error "Failed to get session list"
        return 1
    }
}

# 関数名: get_current_session
# 説明: 現在のセッション名を取得
# 引数: なし
# 戻り値: 0
# 出力: 現在のセッション名
get_current_session() {
    tmux display-message -p '#S' 2>/dev/null || echo ""
}

# 関数名: sort_sessions
# 説明: セッションをソート（現在→アタッチ→デタッチ）
# 引数:
#   $1 - 現在のセッション名
# 戻り値: 0
# 出力: ソートされたセッション情報
sort_sessions() {
    local current="$1"
    # パイプ入力を複数回使えるよう一旦全体を保持
    local sessions
    sessions=$(cat)

    # 現在のセッションを先頭に、その後アタッチ済み、最後にデタッチ
    {
        echo "$sessions" | awk -F '|' -v cur="$current" '($1==cur)'
        echo "$sessions" | awk -F '|' -v cur="$current" '($1!=cur && $3>0)'
        echo "$sessions" | awk -F '|' -v cur="$current" '($1!=cur && $3==0)'
    }
}

# 関数名: format_session_line
# 説明: 1セッションの行をフォーマット
# 引数:
#   $1 - name
#   $2 - windows
#   $3 - attached
#   $4 - created
#   $5 - activity
# 戻り値: 0
# 出力: フォーマット済み行
format_session_line() {
    local name="$1"
    local windows="$2"
    local attached="$3"
    local created="$4"
    local activity="$5"

    # アイコン取得
    local is_current=0
    [[ "$name" == "$CURRENT_SESSION" ]] && is_current=1
    local icon
    icon=$(get_icon "$name" "$attached" "$is_current")

    # 活動マーカー
    local activity_marker
    activity_marker=$(get_activity_marker "$activity")

    # 経過時間
    local time_ago
    time_ago=$(format_time_ago "$activity")

    # セッション名は切り詰めずにそのまま表示（長い名前でも切替に必要な完全な値を保持）
    local display_name
    display_name=$(printf "%-20s" "$name")

    # 色コード設定
    local color_code=""
    local reset="\033[0m"

    if [[ $is_current -eq 1 ]]; then
        color_code="\033[1;32m"  # 緑（太字）
    elif [[ $attached -gt 0 ]]; then
        color_code="\033[1;33m"  # 黄（太字）
    else
        color_code="\033[2;37m"  # グレー（薄く）
    fi

    # フォーマット出力
    printf "%b%s%b  %s %s \033[2m[%2dW]\033[0m  \033[2m%s\033[0m\n" \
        "$color_code" "$display_name" "$reset" \
        "$icon" "$activity_marker" \
        "$windows" "$time_ago"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: セッション一覧を生成して標準出力
# 引数: なし
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    log_debug "Generating session list"

    # 現在のセッション取得
    CURRENT_SESSION=$(get_current_session)
    log_debug "Current session: $CURRENT_SESSION"

    # セッション一覧取得
    local sessions
    if ! sessions=$(get_sessions); then
        log_error "No sessions found"
        echo "No tmux sessions available"
        return 1
    fi

    # ソートとフォーマット
    echo "$sessions" | sort_sessions "$CURRENT_SESSION" | \
    while IFS='|' read -r name windows attached created activity; do
        format_session_line "$name" "$windows" "$attached" "$created" "$activity"
    done

    log_debug "Session list generated successfully"
    return 0
}

main "$@"
