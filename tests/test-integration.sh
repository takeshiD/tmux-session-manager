#!/usr/bin/env bash
# ファイル名: test-integration.sh
# 説明: 統合テスト
# 依存: setup-test-env.sh, すべてのスクリプト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_DIR="${SCRIPT_DIR}/.."

# ====================================================================
# テストケース
# ====================================================================

# テスト: セッション作成→一覧表示→削除
test_session_lifecycle() {
    echo "Test: Session Lifecycle"

    local test_session="test-lifecycle-$$"

    # 作成
    echo "  Creating session: $test_session"
    echo "$test_session" | bash "${PROJECT_DIR}/scripts/actions.sh" new

    if ! tmux has-session -t "$test_session" 2>/dev/null; then
        echo "  ✗ FAIL: Session not created"
        return 1
    fi
    echo "  ✓ Session created"

    # 一覧に表示されるか確認
    local list_output
    list_output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    if ! echo "$list_output" | grep -q "$test_session"; then
        echo "  ✗ FAIL: Session not in list"
        tmux kill-session -t "$test_session"
        return 1
    fi
    echo "  ✓ Session appears in list"

    # プレビュー生成確認
    local preview_output
    preview_output=$(bash "${PROJECT_DIR}/scripts/preview-session.sh" "$test_session")

    if ! echo "$preview_output" | grep -q "$test_session"; then
        echo "  ✗ FAIL: Preview generation failed"
        tmux kill-session -t "$test_session"
        return 1
    fi
    echo "  ✓ Preview generated"

    # 削除
    echo "Yes" | bash "${PROJECT_DIR}/scripts/actions.sh" kill "$test_session"

    if tmux has-session -t "$test_session" 2>/dev/null; then
        echo "  ✗ FAIL: Session not deleted"
        return 1
    fi
    echo "  ✓ Session deleted"

    echo "  ✓ PASS: Session lifecycle test"
    return 0
}

# テスト: 階層的ナビゲーション
test_hierarchical_navigation() {
    echo "Test: Hierarchical Navigation"

    # テストセッション作成
    bash "${SCRIPT_DIR}/setup-test-env.sh" setup

    local test_session="test-session-1"

    # ウィンドウ一覧取得
    local window_list
    window_list=$(bash "${PROJECT_DIR}/scripts/window-list.sh" "$test_session")

    if [[ -z "$window_list" ]]; then
        echo "  ✗ FAIL: Window list is empty"
        bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup
        return 1
    fi
    echo "  ✓ Window list generated"

    # 最初のウィンドウindex取得（行の最初のフィールド）
    local first_window
    first_window=$(echo "$window_list" | head -1 | sed 's/^[^0-9]*//' | awk '{print $1}' | sed 's/:.*//')

    # ペーン一覧取得
    local pane_list
    pane_list=$(bash "${PROJECT_DIR}/scripts/pane-list.sh" "$test_session" "$first_window")

    if [[ -z "$pane_list" ]]; then
        echo "  ✗ FAIL: Pane list is empty"
        bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup
        return 1
    fi
    echo "  ✓ Pane list generated"

    # ウィンドウプレビュー確認
    local window_preview
    window_preview=$(bash "${PROJECT_DIR}/scripts/preview-window.sh" "$test_session" "$first_window")

    if [[ -z "$window_preview" ]]; then
        echo "  ✗ FAIL: Window preview is empty"
        bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup
        return 1
    fi
    echo "  ✓ Window preview generated"

    # クリーンアップ
    bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup

    echo "  ✓ PASS: Hierarchical navigation test"
    return 0
}

# テスト: セッション名変更
test_session_rename() {
    echo "Test: Session Rename"

    # テストセッション作成
    local original_name="test-rename-orig-$$"
    local new_name="test-rename-new-$$"

    echo "$original_name" | bash "${PROJECT_DIR}/scripts/actions.sh" new

    if ! tmux has-session -t "$original_name" 2>/dev/null; then
        echo "  ✗ FAIL: Original session not created"
        return 1
    fi
    echo "  ✓ Original session created"

    # リネーム
    echo "$new_name" | bash "${PROJECT_DIR}/scripts/actions.sh" rename "$original_name"

    if tmux has-session -t "$original_name" 2>/dev/null; then
        echo "  ✗ FAIL: Original session still exists"
        tmux kill-session -t "$original_name" 2>/dev/null || true
        tmux kill-session -t "$new_name" 2>/dev/null || true
        return 1
    fi
    echo "  ✓ Original session renamed"

    if ! tmux has-session -t "$new_name" 2>/dev/null; then
        echo "  ✗ FAIL: New session not found"
        return 1
    fi
    echo "  ✓ New session exists"

    # クリーンアップ
    echo "Yes" | bash "${PROJECT_DIR}/scripts/actions.sh" kill "$new_name"

    echo "  ✓ PASS: Session rename test"
    return 0
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    echo "================================"
    echo "Integration Tests"
    echo "================================"
    echo

    local failed=0

    test_session_lifecycle || failed=$((failed + 1))
    echo

    test_hierarchical_navigation || failed=$((failed + 1))
    echo

    test_session_rename || failed=$((failed + 1))
    echo

    echo "================================"
    if [[ $failed -eq 0 ]]; then
        echo "All integration tests passed! ✓"
        exit 0
    else
        echo "Some integration tests failed: $failed ✗"
        exit 1
    fi
}

main "$@"
