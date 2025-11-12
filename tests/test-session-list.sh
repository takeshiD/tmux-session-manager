#!/usr/bin/env bash
# ファイル名: test-session-list.sh
# 説明: session-list.shの単体テスト
# 依存: setup-test-env.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_DIR="${SCRIPT_DIR}/.."

# テストカウンター
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ====================================================================
# アサーション関数
# ====================================================================

# 関数名: assert_contains
# 説明: 文字列に指定パターンが含まれるかチェック
# 引数:
#   $1 - 検索対象文字列
#   $2 - 検索パターン
#   $3 - メッセージ（オプション）
# 戻り値:
#   0 - パターンが見つかった
#   1 - パターンが見つからなかった
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -q "$needle"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✓ PASS: $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "✗ FAIL: $message"
        echo "  Expected to contain: $needle"
        return 1
    fi
}

# 関数名: assert_not_empty
# 説明: 値が空でないかチェック
# 引数:
#   $1 - チェック対象値
#   $2 - メッセージ（オプション）
# 戻り値:
#   0 - 空でない
#   1 - 空
assert_not_empty() {
    local value="$1"
    local message="${2:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -n "$value" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✓ PASS: $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "✗ FAIL: $message"
        echo "  Expected non-empty value"
        return 1
    fi
}

# ====================================================================
# テストケース
# ====================================================================

# テスト: session-list.shが出力を生成するか
test_session_list_output() {
    echo "Running test: session_list_output"

    local output
    output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    assert_not_empty "$output" "session-list.sh should produce output"
    assert_contains "$output" "test-session-1" "Output should contain test-session-1"
    assert_contains "$output" "test-session-2" "Output should contain test-session-2"
    assert_contains "$output" "test-session-3" "Output should contain test-session-3"
}

# テスト: 出力フォーマットの確認
test_session_list_format() {
    echo "Running test: session_list_format"

    local output
    output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    # アイコンの存在確認（いずれかのアイコンが含まれる）
    if echo "$output" | grep -q "📝\|📎\|💤"; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✓ PASS: Output should contain session icons"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "✗ FAIL: Output should contain session icons"
    fi

    # ウィンドウ数表示の確認
    assert_contains "$output" "\[.*W\]" "Output should show window count"
}

# テスト: 現在のセッションが最初に表示されるか
test_current_session_first() {
    echo "Running test: current_session_first"

    local output
    output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    local current_session
    current_session=$(tmux display-message -p '#S')

    local first_line
    first_line=$(echo "$output" | head -1)

    assert_contains "$first_line" "$current_session" "Current session should be first"
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    echo "================================"
    echo "Testing: session-list.sh"
    echo "================================"
    echo

    # テスト環境セットアップ
    bash "${SCRIPT_DIR}/setup-test-env.sh" setup
    echo

    # テスト実行
    test_session_list_output
    echo
    test_session_list_format
    echo
    test_current_session_first
    echo

    # 結果サマリー
    echo "================================"
    echo "Test Results"
    echo "================================"
    echo "Total:  $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo

    # クリーンアップ
    bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
