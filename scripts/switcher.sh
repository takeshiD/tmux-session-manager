#!/usr/bin/env bash
# ファイル名: switcher.sh
# 説明: メインエントリーポイント
# 依存: config.sh, utils.sh

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# 設定読み込み
# shellcheck source=./config.sh
source "${CURRENT_DIR}/config.sh"

# ユーティリティ読み込み
# shellcheck source=./utils.sh
source "${CURRENT_DIR}/utils.sh"

# ====================================================================
# メイン処理
# ====================================================================

# 関数名: main
# 説明: プラグインメインエントリーポイント
# 引数: なし
# 戻り値:
#   0 - 成功
#   1 - エラー
main() {
    log_info "Starting tmux-session-manager"

    # 依存関係チェック
    if ! check_dependencies; then
        log_error "Dependency check failed"
        tmux display-message "Error: Dependencies not met. Check log at ${LOG_FILE}"
        return 1
    fi

    # popup起動
    log_debug "Launching popup: ${POPUP_WIDTH}x${POPUP_HEIGHT}"

    # tmux popupでsession-modeを起動
    if ! tmux display-popup \
        -E \
        -w "$POPUP_WIDTH" \
        -h "$POPUP_HEIGHT" \
        "bash '${CURRENT_DIR}/session-mode.sh'"; then

        log_error "Failed to launch popup"

        # フォールバック: 通常ウィンドウで起動
        log_warn "Falling back to normal window"
        tmux new-window "bash '${CURRENT_DIR}/session-mode.sh'"
    fi

    log_info "tmux-session-manager finished"
    return 0
}

main "$@"
