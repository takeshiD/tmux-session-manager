#!/usr/bin/env bash
# ファイル名: setup-test-env.sh
# 説明: テスト環境のセットアップとクリーンアップ
# 依存: なし

set -euo pipefail

# テスト用のtmuxセッション作成
setup_test_sessions() {
    local sessions=(
        "test-session-1"
        "test-session-2"
        "test-session-3"
    )

    echo "Setting up test environment..."

    for session in "${sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            tmux new-session -d -s "$session"

            # 複数ウィンドウ作成
            tmux new-window -t "${session}:1" -n "window-1"
            tmux new-window -t "${session}:2" -n "window-2"

            # ペーン分割
            tmux split-window -t "${session}:1" -h
            tmux split-window -t "${session}:1" -v
        fi
    done

    echo "Test environment setup complete"
    echo "Created sessions: ${sessions[*]}"
}

# テスト環境クリーンアップ
cleanup_test_sessions() {
    local sessions=(
        "test-session-1"
        "test-session-2"
        "test-session-3"
    )

    echo "Cleaning up test environment..."

    for session in "${sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            tmux kill-session -t "$session"
            echo "Killed session: $session"
        fi
    done

    echo "Test environment cleaned up"
}

# メイン処理
main() {
    case "${1:-setup}" in
        setup)
            setup_test_sessions
            ;;
        cleanup)
            cleanup_test_sessions
            ;;
        *)
            echo "Usage: $0 {setup|cleanup}"
            exit 1
            ;;
    esac
}

main "$@"
