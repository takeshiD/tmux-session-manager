#!/usr/bin/env bash
# ファイル名: tmux-session-manager.tmux
# 説明: tmuxプラグインエントリーポイント
# 依存: なし

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# ====================================================================
# 設定読み込み
# ====================================================================

# デフォルトキーバインド
readonly DEFAULT_KEY_BINDING="C-m"

# 関数名: get_tmux_option
# 説明: tmux.confからオプション値を取得
# 引数:
#   $1 - オプション名（@プレフィックスなし）
#   $2 - デフォルト値
# 戻り値: 0
# 出力: オプション値
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value
    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

KEY_BINDING=$(get_tmux_option "session-manager-key" "$DEFAULT_KEY_BINDING")

# ====================================================================
# 依存関係チェック
# ====================================================================

# 関数名: check_dependencies
# 説明: 依存関係のチェック
# 引数: なし
# 戻り値:
#   0 - 依存関係OK
#   1 - 依存関係不足
check_dependencies() {
    local errors=0

    # tmuxバージョンチェック
    local tmux_version
    tmux_version=$(tmux -V | cut -d' ' -f2 | tr -d 'a-z')

    # バージョン比較（3.2未満の場合エラー）
    if ! awk -v ver="$tmux_version" 'BEGIN { exit (ver >= 3.2 ? 0 : 1) }'; then
        tmux display-message "Error: tmux 3.2 or higher required (found: $tmux_version)"
        errors=1
    fi

    # fzfチェック
    if ! command -v fzf &> /dev/null; then
        tmux display-message "Error: fzf is not installed"
        errors=1
    fi

    # bashチェック
    if ! command -v bash &> /dev/null; then
        tmux display-message "Error: bash is not installed"
        errors=1
    fi

    return $errors
}

# ====================================================================
# キーバインド登録
# ====================================================================

# 関数名: setup_keybindings
# 説明: キーバインドの設定
# 引数: なし
# 戻り値: 0
setup_keybindings() {
    # メインキーバインド
    tmux bind-key "$KEY_BINDING" run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"

    # プレフィックスキーバインド（オプション、コメントアウト状態）
    # tmux bind-key s run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"
}

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: プラグイン初期化
# 引数: なし
# 戻り値:
#   0 - 初期化成功
#   1 - 初期化失敗
main() {
    # 依存関係チェック
    if ! check_dependencies; then
        tmux display-message "tmux-session-manager: Dependency check failed"
        return 1
    fi

    # キーバインド設定
    setup_keybindings

    # 起動メッセージ（デバッグモード時のみ）
    local debug_mode
    debug_mode=$(get_tmux_option "session-manager-debug" "0")
    if [[ "$debug_mode" == "1" ]]; then
        tmux display-message "tmux-session-manager loaded (key: $KEY_BINDING)"
    fi

    return 0
}

main
