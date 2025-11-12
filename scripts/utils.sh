#!/usr/bin/env bash
# ファイル名: utils.sh
# 説明: 共通ユーティリティ関数
# 依存: なし

# ====================================================================
# グローバル変数
# ====================================================================

# ログレベル定義
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
)

# 現在のログレベル（環境変数から取得、デフォルトはINFO）
CURRENT_LOG_LEVEL="${TMUX_SESSION_MANAGER_LOG_LEVEL:-INFO}"
LOG_FILE="${TMUX_SESSION_MANAGER_LOG_FILE:-/tmp/tmux-session-manager.log}"

# ====================================================================
# ログ関数
# ====================================================================

# 関数名: log_message
# 説明: ログメッセージを出力
# 引数:
#   $1 - ログレベル (DEBUG/INFO/WARN/ERROR)
#   $@ - メッセージ
# 戻り値: なし
# 出力: ログファイルへの書き込み、ERRORの場合はtmux表示
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # レベルチェック
    if [[ ${LOG_LEVELS[$level]:-0} -ge ${LOG_LEVELS[$CURRENT_LOG_LEVEL]:-1} ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"

        # ERRORの場合はtmuxにも表示
        if [[ "$level" == "ERROR" ]]; then
            tmux display-message "[Error] ${message}" 2>/dev/null || true
        fi
    fi
}

log_debug() { log_message DEBUG "$@"; }
log_info()  { log_message INFO "$@"; }
log_warn()  { log_message WARN "$@"; }
log_error() { log_message ERROR "$@"; }

# ====================================================================
# 時間フォーマット関数
# ====================================================================

# 関数名: format_time_ago
# 説明: Unix timestampから経過時間をフォーマット
# 引数:
#   $1 - Unix timestamp
# 戻り値: 0
# 出力: "2h", "30m", "3d" などのフォーマット済み文字列
format_time_ago() {
    local timestamp="$1"
    local now
    now=$(date +%s)
    local diff=$((now - timestamp))

    if [[ $diff -lt 60 ]]; then
        echo "${diff}s"
    elif [[ $diff -lt 3600 ]]; then
        echo "$((diff / 60))m"
    elif [[ $diff -lt 86400 ]]; then
        echo "$((diff / 3600))h"
    else
        echo "$((diff / 86400))d"
    fi
}

# ====================================================================
# アイコン取得関数
# ====================================================================

# 関数名: get_icon
# 説明: セッション状態に応じたアイコン取得
# 引数:
#   $1 - session_name
#   $2 - is_attached (0 or 1以上)
#   $3 - is_current (0 or 1)
# 戻り値: 0
# 出力: アイコンと色コード
get_icon() {
    local session_name="$1"
    local is_attached="$2"
    local is_current="$3"

    if [[ "$is_current" == "1" ]]; then
        echo -e "\033[1;32m📝\033[0m"  # 緑色の編集アイコン
    elif [[ "$is_attached" -gt 0 ]]; then
        echo -e "\033[1;33m📎\033[0m"  # 黄色のクリップ
    else
        echo -e "\033[2;37m💤\033[0m"  # グレーのスリープ
    fi
}

# ====================================================================
# 活動マーカー取得関数
# ====================================================================

# 関数名: get_activity_marker
# 説明: 最終活動時刻に基づく活動マーカー取得
# 引数:
#   $1 - 最終活動時刻（Unix timestamp）
# 戻り値: 0
# 出力: 活動マーカー（🔥/⚡/空白）
get_activity_marker() {
    local activity="$1"
    local now
    now=$(date +%s)
    local diff=$((now - activity))

    if [[ $diff -lt 300 ]]; then      # 5分以内
        echo "🔥"
    elif [[ $diff -lt 3600 ]]; then   # 1時間以内
        echo "⚡"
    else
        echo "  "
    fi
}

# ====================================================================
# バリデーション関数
# ====================================================================

# 関数名: validate_session_name
# 説明: セッション名のバリデーション
# 引数:
#   $1 - セッション名
# 戻り値:
#   0 - 有効
#   1 - 無効
# 出力: エラーメッセージ（無効時）
validate_session_name() {
    local name="$1"

    # 空文字チェック
    if [[ -z "$name" ]]; then
        log_error "Session name cannot be empty"
        return 1
    fi

    # 特殊文字チェック（.と:は使用不可）
    if [[ "$name" =~ [.:] ]]; then
        log_error "Session name cannot contain '.' or ':'"
        return 1
    fi

    # 長さチェック（最大50文字）
    if [[ ${#name} -gt 50 ]]; then
        log_error "Session name too long (max 50 characters)"
        return 1
    fi

    return 0
}

# ====================================================================
# 文字列操作関数
# ====================================================================

# 関数名: truncate_string
# 説明: 文字列を指定長に切り詰め
# 引数:
#   $1 - 文字列
#   $2 - 最大長
# 戻り値: 0
# 出力: 切り詰められた文字列
truncate_string() {
    local str="$1"
    local max_len="$2"

    if [[ ${#str} -le $max_len ]]; then
        echo "$str"
    else
        echo "${str:0:$((max_len - 3))}..."
    fi
}

# ====================================================================
# 依存関係チェック関数
# ====================================================================

# 関数名: version_compare
# 説明: バージョン番号の比較
# 引数:
#   $1 - バージョン1
#   $2 - バージョン2（最小要求）
# 戻り値:
#   0 - バージョン1 >= バージョン2
#   1 - バージョン1 < バージョン2
version_compare() {
    local version1="$1"
    local version2="$2"

    # sort -Vでバージョン比較
    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

# 関数名: check_dependencies
# 説明: 依存関係チェック
# 引数: なし
# 戻り値:
#   0 - すべての依存関係OK
#   1 - 依存関係不足
# 出力: エラーメッセージ（依存不足時）
check_dependencies() {
    local missing_deps=()
    local errors=0

    # tmuxバージョンチェック
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
        errors=1
    else
        local tmux_version
        tmux_version=$(tmux -V | cut -d' ' -f2 | tr -d 'a-z')

        if ! version_compare "$tmux_version" "3.2"; then
            log_error "tmux version 3.2 or higher required (found: $tmux_version)"
            errors=1
        fi
    fi

    # fzfチェック
    if ! command -v fzf &> /dev/null; then
        missing_deps+=("fzf")
        errors=1
    else
        local fzf_version
        fzf_version=$(fzf --version | cut -d' ' -f1)

        if ! version_compare "$fzf_version" "0.30.0"; then
            log_warn "fzf version 0.30.0 or higher recommended (found: $fzf_version)"
        fi
    fi

    # bashバージョンチェック
    local bash_version="${BASH_VERSION%%.*}"
    if [[ $bash_version -lt 4 ]]; then
        log_error "bash version 4.0 or higher required (found: $BASH_VERSION)"
        errors=1
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        errors=1
    fi

    return $errors
}

# ====================================================================
# エラーハンドリング関数
# ====================================================================

# 関数名: safe_tmux
# 説明: tmuxコマンドの安全な実行
# 引数:
#   $@ - tmuxコマンドの引数
# 戻り値:
#   tmuxコマンドの終了コード
# 出力: tmuxコマンドの出力
safe_tmux() {
    local output
    local exit_code

    if ! output=$(tmux "$@" 2>&1); then
        exit_code=$?
        log_error "tmux command failed: tmux $*"
        log_error "Output: $output"
        return $exit_code
    fi

    echo "$output"
    return 0
}
