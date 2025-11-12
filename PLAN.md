# tmux Session Switcher - 詳細設計書

**バージョン:** 1.0
**作成日:** 2025-11-12
**基準仕様書:** CLAUDE.md v1.0

---

## 目次

1. [実装フェーズ計画](#1-実装フェーズ計画)
2. [ディレクトリ構造と初期化](#2-ディレクトリ構造と初期化)
3. [共通設計パターン](#3-共通設計パターン)
4. [各スクリプトファイルの詳細設計](#4-各スクリプトファイルの詳細設計)
5. [データ構造定義](#5-データ構造定義)
6. [テーマシステム設計](#6-テーマシステム設計)
7. [エラーハンドリング戦略](#7-エラーハンドリング戦略)
8. [テスト実装計画](#8-テスト実装計画)
9. [実装チェックリスト](#9-実装チェックリスト)

---

## 1. 実装フェーズ計画

### Phase 1: 基盤構築（1-2日）

```
優先度: 最高
目標: プラグインの基本構造と共通機能の実装
```

#### 1.1 ファイル作成
- [ ] ディレクトリ構造の作成
- [ ] tmux-session-switcher.tmux（プラグインエントリー）
- [ ] scripts/utils.sh（共通ユーティリティ）
- [ ] scripts/config.sh（設定管理）

#### 1.2 実装タスク
1. **utils.sh**: 共通関数の実装
   - ログ関数
   - バリデーション関数
   - フォーマット関数
   - 時間計算関数

2. **config.sh**: 設定読み込み
   - tmux.confからの設定取得
   - デフォルト値の定義
   - 環境変数の設定

3. **tmux-session-switcher.tmux**: プラグイン登録
   - キーバインド設定
   - 依存関係チェック

### Phase 2: コア機能実装（3-4日）

```
優先度: 高
目標: セッション一覧とプレビュー機能の実装
```

#### 2.1 ファイル作成
- [ ] scripts/switcher.sh
- [ ] scripts/session-list.sh
- [ ] scripts/preview-session.sh
- [ ] scripts/session-mode.sh

#### 2.2 実装タスク
1. **session-list.sh**: セッション一覧生成
   - tmux APIからのデータ取得
   - フォーマット処理
   - ソート機能

2. **preview-session.sh**: セッション詳細表示
   - セッション情報の整形
   - ウィンドウリストの生成
   - ペーン内容のプレビュー

3. **session-mode.sh**: UI制御
   - fzfの起動と設定
   - キーバインド処理
   - 結果の処理

4. **switcher.sh**: エントリーポイント
   - popup起動
   - エラーハンドリング

### Phase 3: 詳細機能実装（2-3日）

```
優先度: 高
目標: ウィンドウ・ペーンレベルの操作実装
```

#### 3.1 ファイル作成
- [ ] scripts/detail-mode.sh
- [ ] scripts/window-list.sh
- [ ] scripts/preview-window.sh
- [ ] scripts/pane-mode.sh
- [ ] scripts/pane-list.sh
- [ ] scripts/preview-pane.sh

#### 3.2 実装タスク
1. ウィンドウモードの実装
2. ペーンモードの実装
3. 階層的ナビゲーションの統合

### Phase 4: CRUD操作実装（2日）

```
優先度: 中
目標: セッション管理機能の実装
```

#### 4.1 ファイル作成
- [ ] scripts/actions.sh

#### 4.2 実装タスク
1. 新規作成機能
2. リネーム機能
3. 削除機能（安全機構含む）

### Phase 5: テーマとUI改善（1-2日）

```
優先度: 中
目標: カラーテーマとUI調整
```

#### 5.1 実装タスク
1. Tokyo Nightテーマ
2. Catppuccinテーマ
3. デフォルトテーマ
4. ヘッダー・フッターの最適化
5. CLAUDE.md / README.md のテーマ構成反映
6. テーマ未配置時のdefaultフォールバック実装と自動テスト

### Phase 6: テストと最適化（2-3日）

```
優先度: 高
目標: 品質保証とパフォーマンス調整
```

#### 6.1 実装タスク
1. 単体テストの作成
2. 統合テストの実行
3. エッジケースの対応
4. パフォーマンス測定と最適化

---

## 2. ディレクトリ構造と初期化

### 2.1 完全なディレクトリ構造

```
tmux-session-manager/
├── README.md
├── LICENSE
├── .gitignore
├── CLAUDE.md                          # 仕様書
├── PLAN.md                            # 本詳細設計書
│
├── tmux-session-switcher.tmux         # プラグインエントリー
│
├── scripts/
│   ├── switcher.sh                    # メインエントリーポイント
│   ├── config.sh                      # 設定管理
│   ├── utils.sh                       # 共通ユーティリティ
│   │
│   ├── session-mode.sh                # セッション選択モード
│   ├── detail-mode.sh                 # ウィンドウ選択モード
│   ├── pane-mode.sh                   # ペーン選択モード
│   │
│   ├── session-list.sh                # セッション一覧生成
│   ├── window-list.sh                 # ウィンドウ一覧生成
│   ├── pane-list.sh                   # ペーン一覧生成
│   │
│   ├── preview-session.sh             # セッションプレビュー
│   ├── preview-window.sh              # ウィンドウプレビュー
│   ├── preview-pane.sh                # ペーンプレビュー
│   │
│   └── actions.sh                     # CRUD操作
│
├── docs/
│   ├── ARCHITECTURE.md                # アーキテクチャ詳細
│   ├── DEVELOPMENT.md                 # 開発ガイド
│   └── images/
│
└── tests/
    ├── test-session-list.sh
    ├── test-window-list.sh
    ├── test-pane-list.sh
    ├── test-actions.sh
    ├── test-integration.sh
    └── fixtures/
        └── test-sessions.sh
```

### 2.2 初期化スクリプト

```bash
#!/usr/bin/env bash
# setup.sh - プロジェクト初期化スクリプト

set -euo pipefail

# ディレクトリ作成
mkdir -p scripts
mkdir -p docs/images
mkdir -p tests/fixtures

# 実行権限付与
find scripts -type f -name "*.sh" -exec chmod +x {} \;
find tests -type f -name "*.sh" -exec chmod +x {} \;

echo "Project structure initialized successfully!"
```

---

## 3. 共通設計パターン

### 3.1 スクリプトテンプレート

すべてのスクリプトファイルは以下のテンプレートに従う：

```bash
#!/usr/bin/env bash
# ファイル名: <script-name>.sh
# 説明: <script description>
# 依存: <dependencies>

set -euo pipefail

# ====================================================================
# グローバル変数
# ====================================================================

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# 設定ファイル読み込み
if [[ -f "${CURRENT_DIR}/config.sh" ]]; then
    # shellcheck source=./config.sh
    source "${CURRENT_DIR}/config.sh"
fi

# ユーティリティ読み込み
if [[ -f "${CURRENT_DIR}/utils.sh" ]]; then
    # shellcheck source=./utils.sh
    source "${CURRENT_DIR}/utils.sh"
fi

# ====================================================================
# 関数定義
# ====================================================================

# 関数名: <function_name>
# 説明: <function description>
# 引数:
#   $1 - <arg1 description>
#   $2 - <arg2 description>
# 戻り値:
#   0 - 成功
#   1 - エラー
# 出力: <output description>
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"

    # 実装
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    # バリデーション

    # 処理実行

    # 結果出力
}

# スクリプト直接実行時のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 3.2 エラーハンドリングパターン

```bash
# パターン1: 早期リターン
validate_input() {
    local input="$1"

    if [[ -z "$input" ]]; then
        log_error "Input is empty"
        return 1
    fi

    if ! [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Input contains invalid characters"
        return 1
    fi

    return 0
}

# パターン2: エラートラップ
setup_error_trap() {
    trap 'handle_error $? $LINENO' ERR
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Error occurred at line ${line_number} with exit code ${exit_code}"
}

# パターン3: コマンド実行のラップ
safe_tmux() {
    local output
    if ! output=$(tmux "$@" 2>&1); then
        log_error "tmux command failed: tmux $*"
        log_error "Output: $output"
        return 1
    fi
    echo "$output"
}
```

### 3.3 データパイプラインパターン

```bash
# データ取得 → 変換 → フォーマット → 出力
process_sessions() {
    tmux list-sessions -F "#{session_name}|..." 2>/dev/null | \
        sort_sessions | \
        format_sessions | \
        colorize_output
}

# 各ステップは標準入出力で連携
sort_sessions() {
    local current_session
    current_session=$(tmux display-message -p '#S' 2>/dev/null)

    # 現在のセッションを先頭に
    {
        grep "^${current_session}|" || true
        grep -v "^${current_session}|" || true
    }
}

format_sessions() {
    while IFS='|' read -r name windows attached created activity; do
        printf "%-20s [%2dW] %s\n" "$name" "$windows" "..."
    done
}
```

---

## 4. 各スクリプトファイルの詳細設計

### 4.1 utils.sh

#### 4.1.1 目的
共通ユーティリティ関数の提供

#### 4.1.2 関数一覧

##### log_debug / log_info / log_warn / log_error

```bash
# ログレベル定義
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
)

# 現在のログレベル（環境変数から取得）
CURRENT_LOG_LEVEL="${TMUX_SESSION_SWITCHER_LOG_LEVEL:-INFO}"
LOG_FILE="${TMUX_SESSION_SWITCHER_LOG_FILE:-/tmp/tmux-session-switcher.log}"

# ログ出力関数
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # レベルチェック
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$CURRENT_LOG_LEVEL]} ]]; then
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
```

##### format_time_ago

```bash
# 経過時間のフォーマット
# 引数: Unix timestamp
# 出力: "2h", "30m", "3d" など
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
```

##### get_icon

```bash
# セッション状態に応じたアイコン取得
# 引数:
#   $1 - session_name
#   $2 - is_attached (0 or 1)
#   $3 - is_current (0 or 1)
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
```

##### get_activity_marker

```bash
# 活動マーカー取得
# 引数: 最終活動時刻（Unix timestamp）
# 出力: 活動マーカー
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
```

##### validate_session_name

```bash
# セッション名のバリデーション
# 引数: セッション名
# 戻り値: 0=有効, 1=無効
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
```

##### truncate_string

```bash
# 文字列を指定長に切り詰め
# 引数:
#   $1 - 文字列
#   $2 - 最大長
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
```

##### check_dependencies

```bash
# 依存関係チェック
# 戻り値: 0=OK, 1=依存不足
check_dependencies() {
    local missing_deps=()

    # tmuxバージョンチェック
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    else
        local tmux_version
        tmux_version=$(tmux -V | cut -d' ' -f2)
        if ! version_compare "$tmux_version" "3.2"; then
            log_error "tmux version 3.2 or higher required (found: $tmux_version)"
            return 1
        fi
    fi

    # fzfチェック
    if ! command -v fzf &> /dev/null; then
        missing_deps+=("fzf")
    else
        local fzf_version
        fzf_version=$(fzf --version | cut -d' ' -f1)
        if ! version_compare "$fzf_version" "0.30.0"; then
            log_warn "fzf version 0.30.0 or higher recommended (found: $fzf_version)"
        fi
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# バージョン比較ヘルパー
version_compare() {
    local version1="$1"
    local version2="$2"

    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}
```

### 4.2 config.sh

#### 4.2.1 目的
設定の一元管理と環境変数の初期化

#### 4.2.2 実装

```bash
#!/usr/bin/env bash
# config.sh - 設定管理

# ====================================================================
# デフォルト設定
# ====================================================================

# ポップアップサイズ
DEFAULT_POPUP_WIDTH="95%"
DEFAULT_POPUP_HEIGHT="90%"
DEFAULT_PREVIEW_WIDTH="65"

# カラーテーマ
DEFAULT_THEME="tokyonight"

# キーバインド
DEFAULT_KEY_BINDING="C-s"

# ログ設定
DEFAULT_LOG_LEVEL="INFO"
DEFAULT_LOG_FILE="/tmp/tmux-session-switcher.log"

# ====================================================================
# tmux.confから設定取得
# ====================================================================

# tmuxオプション取得ヘルパー
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value

    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

# ====================================================================
# グローバル変数設定
# ====================================================================

# ポップアップ設定
export POPUP_WIDTH=$(get_tmux_option "session-switcher-popup-width" "$DEFAULT_POPUP_WIDTH")
export POPUP_HEIGHT=$(get_tmux_option "session-switcher-popup-height" "$DEFAULT_POPUP_HEIGHT")
export PREVIEW_WIDTH=$(get_tmux_option "session-switcher-preview-width" "$DEFAULT_PREVIEW_WIDTH")

# テーマ設定
export THEME=$(get_tmux_option "session-switcher-theme" "$DEFAULT_THEME")

# ログ設定
export LOG_LEVEL=$(get_tmux_option "session-switcher-log-level" "$DEFAULT_LOG_LEVEL")
export LOG_FILE=$(get_tmux_option "session-switcher-log-file" "$DEFAULT_LOG_FILE")

# デバッグモード
export DEBUG_MODE=$(get_tmux_option "session-switcher-debug" "0")

# ====================================================================
# fzfオプション構築
# ====================================================================

# テーマごとのカラー設定
get_theme_colors() {
    local theme="$1"

    case "$theme" in
        tokyonight)
            echo "--color=bg+:#364a82,bg:#1a1b26,border:#7aa2f7,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
            ;;
        catppuccin)
            echo "--color=bg+:#313244,bg:#1e1e2e,border:#89b4fa,fg:#cdd6f4,fg+:#cdd6f4,hl:#89b4fa,hl+:#94e2d5,info:#89b4fa,prompt:#94e2d5,pointer:#f38ba8,marker:#a6e3a1,spinner:#a6e3a1,header:#a6e3a1"
            ;;
        default)
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# 基本fzfオプション
get_base_fzf_options() {
    local theme_colors
    theme_colors=$(get_theme_colors "$THEME")

    echo "--ansi --border=rounded --height=100% $theme_colors"
}

# プレビューウィンドウオプション
get_preview_window_options() {
    echo "right:${PREVIEW_WIDTH}%:wrap:border-left"
}
```

### 4.3 tmux-session-switcher.tmux

#### 4.3.1 目的
tmuxプラグインとしての登録とキーバインド設定

#### 4.3.2 実装

```bash
#!/usr/bin/env bash
# tmux-session-switcher.tmux - プラグインエントリーポイント

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURRENT_DIR

# ====================================================================
# 設定読み込み
# ====================================================================

# デフォルトキーバインド
DEFAULT_KEY_BINDING="C-s"

# tmux.confから設定取得
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value
    value=$(tmux show-option -gqv "@${option}" 2>/dev/null)
    echo "${value:-$default}"
}

KEY_BINDING=$(get_tmux_option "session-switcher-key" "$DEFAULT_KEY_BINDING")

# ====================================================================
# 依存関係チェック
# ====================================================================

check_dependencies() {
    local errors=0

    # tmuxバージョンチェック
    local tmux_version
    tmux_version=$(tmux -V | cut -d' ' -f2 | tr -d 'a-z')

    if ! awk -v ver="$tmux_version" 'BEGIN { exit (ver >= 3.2 ? 0 : 1) }'; then
        tmux display-message "Error: tmux 3.2 or higher required (found: $tmux_version)"
        errors=1
    fi

    # fzfチェック
    if ! command -v fzf &> /dev/null; then
        tmux display-message "Error: fzf is not installed"
        errors=1
    fi

    return $errors
}

# ====================================================================
# キーバインド登録
# ====================================================================

setup_keybindings() {
    # メインキーバインド
    tmux bind-key "$KEY_BINDING" run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"

    # プレフィックスキーバインド（オプション）
    # tmux bind-key s run-shell "bash '${CURRENT_DIR}/scripts/switcher.sh'"
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    # 依存関係チェック
    if ! check_dependencies; then
        tmux display-message "tmux-session-switcher: Dependency check failed"
        return 1
    fi

    # キーバインド設定
    setup_keybindings

    # 起動メッセージ（デバッグモード時のみ）
    local debug_mode
    debug_mode=$(get_tmux_option "session-switcher-debug" "0")
    if [[ "$debug_mode" == "1" ]]; then
        tmux display-message "tmux-session-switcher loaded (key: $KEY_BINDING)"
    fi
}

main
```

### 4.4 switcher.sh

#### 4.4.1 目的
プラグインのメインエントリーポイント。tmux popupを起動し、session-mode.shを実行

#### 4.4.2 実装

```bash
#!/usr/bin/env bash
# switcher.sh - メインエントリーポイント

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

main() {
    log_info "Starting tmux-session-switcher"

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

    log_info "tmux-session-switcher finished"
}

main "$@"
```

### 4.5 session-list.sh

#### 4.5.1 目的
セッション一覧のフォーマット済みテキスト生成

#### 4.5.2 データフロー

```
tmux list-sessions
    ↓
parse_session_data (生データをパース)
    ↓
sort_sessions (現在→アタッチ→デタッチ)
    ↓
format_session_line (1行ずつフォーマット)
    ↓
標準出力
```

#### 4.5.3 実装

```bash
#!/usr/bin/env bash
# session-list.sh - セッション一覧生成

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

# セッション情報取得
get_sessions() {
    tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}|#{session_activity}" 2>/dev/null || {
        log_error "Failed to get session list"
        return 1
    }
}

# 現在のセッション取得
get_current_session() {
    tmux display-message -p '#S' 2>/dev/null || echo ""
}

# セッション情報のパース
parse_session_data() {
    local line="$1"
    local -A session_data

    IFS='|' read -r name windows attached created activity <<< "$line"

    session_data[name]="$name"
    session_data[windows]="$windows"
    session_data[attached]="$attached"
    session_data[created]="$created"
    session_data[activity]="$activity"

    # 連想配列を文字列として返す（bashの制限回避）
    echo "name=${name}|windows=${windows}|attached=${attached}|created=${created}|activity=${activity}"
}

# セッションのソート
sort_sessions() {
    local current="$1"

    # 現在のセッションを先頭に、その後アタッチ済み、最後にデタッチ
    {
        grep "^${current}|" || true
        grep -v "^${current}|" | grep "|[1-9][0-9]*|" || true
        grep -v "^${current}|" | grep "|0|" || true
    }
}

# 1セッションの行フォーマット
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

    # セッション名を切り詰め
    local display_name
    display_name=$(truncate_string "$name" 20)
    display_name=$(printf "%-20s" "$display_name")

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
}

main "$@"
```

### 4.6 preview-session.sh

#### 4.6.1 目的
セッション詳細情報の生成

#### 4.6.2 出力構造

```
┌─ ヘッダー（ボックス装飾）
├─ セッション基本情報
├─ ウィンドウ一覧
└─ アクティブウィンドウのペーンプレビュー
```

#### 4.6.3 実装

```bash
#!/usr/bin/env bash
# preview-session.sh - セッションプレビュー生成

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

readonly BOX_WIDTH=60
readonly PREVIEW_LINES=15

# ====================================================================
# 関数定義
# ====================================================================

# ヘッダーボックス生成
print_header() {
    local session_name="$1"
    local name_display
    name_display=$(truncate_string "$session_name" $((BOX_WIDTH - 15)))

    echo -e "\033[1;35m╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m📦 Session: ${name_display}\033[0m"
    echo -e "\033[1;35m╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝\033[0m"
    echo
}

# セッション基本情報取得
get_session_info() {
    local session_name="$1"

    local info
    info=$(tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_windows}|#{session_created}|#{session_activity}" 2>/dev/null | \
        grep "^${session_name}|" | head -1)

    if [[ -z "$info" ]]; then
        log_error "Session not found: $session_name"
        return 1
    fi

    echo "$info"
}

# セッション情報表示
print_session_info() {
    local session_name="$1"
    local attached="$2"
    local windows="$3"
    local created="$4"
    local activity="$5"

    local status
    [[ $attached -gt 0 ]] && status="attached" || status="detached"

    local created_ago
    created_ago=$(format_time_ago "$created")

    local activity_ago
    activity_ago=$(format_time_ago "$activity")

    echo -e "\033[1;34m┌─ Info\033[0m"
    echo -e "\033[1;34m├─\033[0m Status:       \033[1;33m${status}\033[0m"
    echo -e "\033[1;34m├─\033[0m Windows:      \033[1;32m${windows}\033[0m"
    echo -e "\033[1;34m├─\033[0m Created:      \033[2m${created_ago} ago\033[0m"
    echo -e "\033[1;34m└─\033[0m Last Activity: \033[2m${activity_ago} ago\033[0m"
    echo
}

# ウィンドウ一覧取得
get_windows() {
    local session_name="$1"

    tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}|#{window_panes}|#{window_active}" \
        2>/dev/null || {
        log_error "Failed to get windows for session: $session_name"
        return 1
    }
}

# ウィンドウ一覧表示
print_windows() {
    local session_name="$1"

    echo -e "\033[1;34m┌─ Windows\033[0m"

    local windows
    windows=$(get_windows "$session_name")

    echo "$windows" | while IFS='|' read -r idx name panes active; do
        local marker color
        if [[ "$active" == "1" ]]; then
            marker="❯"
            color="\033[1;32m"
        else
            marker="│"
            color="\033[2m"
        fi

        local display_name
        display_name=$(truncate_string "$name" 30)

        printf "%b%s %2d: %-30s \033[2m[%dP]\033[0m\n" \
            "$color" "$marker" "$idx" "$display_name" "$panes"
    done

    echo
}

# アクティブウィンドウのプレビュー
print_active_pane_preview() {
    local session_name="$1"

    # アクティブウィンドウindex取得
    local active_window
    active_window=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_active}" 2>/dev/null | \
        grep "|1$" | cut -d'|' -f1 | head -1)

    if [[ -z "$active_window" ]]; then
        log_warn "No active window found"
        return
    fi

    # ウィンドウ名取得
    local window_name
    window_name=$(tmux list-windows -t "$session_name" \
        -F "#{window_index}|#{window_name}" 2>/dev/null | \
        grep "^${active_window}|" | cut -d'|' -f2)

    echo -e "\033[1;34m┌─ Active Window Preview: \033[1;36m${window_name}\033[0m"

    # ペーン内容キャプチャ
    if ! tmux capture-pane -t "${session_name}:${active_window}.0" -p 2>/dev/null | head -${PREVIEW_LINES} | \
        while IFS= read -r line; do
            echo -e "\033[1;34m│\033[0m   $line"
        done; then
        echo -e "\033[1;34m│\033[0m   \033[2m(Preview not available)\033[0m"
    fi

    echo -e "\033[1;34m└─\033[0m \033[2m(Showing first ${PREVIEW_LINES} lines of pane 0)\033[0m"
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    local session_name="$1"

    log_debug "Generating preview for session: $session_name"

    # セッション情報取得
    local info
    if ! info=$(get_session_info "$session_name"); then
        echo "Error: Session not found"
        return 1
    fi

    # パース
    IFS='|' read -r name attached windows created activity <<< "$info"

    # 描画
    print_header "$name"
    print_session_info "$name" "$attached" "$windows" "$created" "$activity"
    print_windows "$name"
    print_active_pane_preview "$name"

    log_debug "Preview generated successfully"
}

# 引数チェック
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <session_name>"
    exit 1
fi

main "$@"
```

### 4.7 session-mode.sh

#### 4.7.1 目的
セッション選択UIの制御とユーザー操作のハンドリング

#### 4.7.2 キーバインド処理

| キー | アクション | 実装 |
|------|-----------|------|
| Enter | セッション切り替え | `become(echo switch {})` |
| Space | ウィンドウモードへ | `execute(detail-mode.sh {})` |
| Ctrl-n | 新規作成 | `execute(actions.sh new)+reload` |
| Ctrl-r | リネーム | `execute(actions.sh rename {})+reload` |
| Ctrl-x | 削除 | `execute(actions.sh kill {})+reload` |
| Ctrl-/ | プレビュー切替 | `toggle-preview` |
| q | 終了 | `abort` |

#### 4.7.3 実装

```bash
#!/usr/bin/env bash
# session-mode.sh - セッション選択モード

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

readonly HEADER="┃ ⏎ Switch │ ␣ Details │ Ctrl-n New │ Ctrl-r Rename │ Ctrl-x Delete │ Ctrl-/ Preview │ q Quit ┃"
readonly PROMPT="🔍 Sessions > "

# ====================================================================
# 関数定義
# ====================================================================

# fzfオプション構築
build_fzf_options() {
    local base_options preview_window theme_colors

    base_options=$(get_base_fzf_options)
    preview_window=$(get_preview_window_options)

    echo "$base_options \
        --header='$HEADER' \
        --prompt='$PROMPT' \
        --preview='bash ${CURRENT_DIR}/preview-session.sh {1}' \
        --preview-window='$preview_window' \
        --bind='enter:become(echo switch {1})' \
        --bind='space:execute(bash ${CURRENT_DIR}/detail-mode.sh {1})+abort' \
        --bind='ctrl-n:execute(bash ${CURRENT_DIR}/actions.sh new)+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-r:execute(bash ${CURRENT_DIR}/actions.sh rename {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-x:execute(bash ${CURRENT_DIR}/actions.sh kill {1})+reload(bash ${CURRENT_DIR}/session-list.sh)' \
        --bind='ctrl-/:toggle-preview' \
        --bind='q:abort' \
        --expect='enter,space'"
}

# セッション切り替え実行
switch_to_session() {
    local session_name="$1"

    log_info "Switching to session: $session_name"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        log_error "Session does not exist: $session_name"
        tmux display-message "Error: Session '$session_name' not found"
        return 1
    fi

    tmux switch-client -t "$session_name"
}

# 結果処理
process_result() {
    local result="$1"

    # 空の場合は何もしない
    if [[ -z "$result" ]]; then
        log_debug "No selection made"
        return 0
    fi

    # 最初の行がキー、2行目が選択内容
    local key
    key=$(echo "$result" | head -1)
    local selection
    selection=$(echo "$result" | tail -1)

    log_debug "Key: $key, Selection: $selection"

    # セッション名抽出（最初のフィールド）
    local session_name
    session_name=$(echo "$selection" | awk '{print $1}')

    # キーに応じた処理
    case "$key" in
        enter)
            if [[ "$selection" =~ ^switch ]]; then
                # become経由の場合
                session_name=$(echo "$selection" | awk '{print $2}')
                switch_to_session "$session_name"
            else
                # 通常のEnter
                switch_to_session "$session_name"
            fi
            ;;
        space)
            # detail-modeに遷移（executeで実行済み）
            log_debug "Transitioning to detail-mode"
            ;;
        *)
            log_debug "Unknown key: $key"
            ;;
    esac
}

# ====================================================================
# メイン処理
# ====================================================================

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
}

main "$@"
```

---

## 5. データ構造定義

### 5.1 セッションデータ構造

```bash
# セッション情報（パイプ区切り）
SESSION_DATA="name|windows|attached|created|activity"

# 例:
# "dev-project|5|1|1699000000|1699001000"

# フィールド定義:
# - name: セッション名（文字列）
# - windows: ウィンドウ数（整数）
# - attached: アタッチ数（整数、0=デタッチ、1以上=アタッチ）
# - created: 作成時刻（Unix timestamp）
# - activity: 最終活動時刻（Unix timestamp）
```

### 5.2 ウィンドウデータ構造

```bash
# ウィンドウ情報（パイプ区切り）
WINDOW_DATA="index|name|panes|active"

# 例:
# "0|editor|3|1"

# フィールド定義:
# - index: ウィンドウindex（整数）
# - name: ウィンドウ名（文字列）
# - panes: ペーン数（整数）
# - active: アクティブフラグ（0 or 1）
```

### 5.3 ペーンデータ構造

```bash
# ペーン情報（パイプ区切り）
PANE_DATA="index|command|width|height|active|pid"

# 例:
# "0|nvim|120|30|1|12345"

# フィールド定義:
# - index: ペーンindex（整数）
# - command: 実行中のコマンド（文字列）
# - width: 幅（整数）
# - height: 高さ（整数）
# - active: アクティブフラグ（0 or 1）
# - pid: プロセスID（整数）
```

---

## 6. テーマシステム設計

### 6.1 テーマ構造

```bash
# themes/tokyonight.sh

declare -A TOKYONIGHT_COLORS=(
    # 背景・前景
    [bg]="#1a1b26"
    [bg_plus]="#364a82"
    [fg]="#c0caf5"
    [fg_plus]="#c0caf5"

    # ボーダー
    [border]="#7aa2f7"

    # ハイライト
    [hl]="#7aa2f7"
    [hl_plus]="#7dcfff"

    # UI要素
    [info]="#7aa2f7"
    [prompt]="#7dcfff"
    [pointer]="#f7768e"
    [marker]="#9ece6a"
    [spinner]="#9ece6a"
    [header]="#9ece6a"
)

# fzf用カラー文字列生成
generate_fzf_colors() {
    local -n colors=$1

    echo "--color=bg+:${colors[bg_plus]},bg:${colors[bg]},border:${colors[border]},fg:${colors[fg]},fg+:${colors[fg_plus]},hl:${colors[hl]},hl+:${colors[hl_plus]},info:${colors[info]},prompt:${colors[prompt]},pointer:${colors[pointer]},marker:${colors[marker]},spinner:${colors[spinner]},header:${colors[header]}"
}
```

### 6.2 テーマファイル配置

```
scripts/
├── themes/
│   ├── tokyonight.sh
│   ├── catppuccin.sh
│   └── default.sh
```

### 6.3 テーマ読み込み

```bash
# config.sh内
load_theme() {
    local theme="$1"
    local theme_file="${CURRENT_DIR}/themes/${theme}.sh"

    if [[ -f "$theme_file" ]]; then
        # shellcheck source=/dev/null
        source "$theme_file"
        log_debug "Loaded theme: $theme"
    else
        log_warn "Theme file not found: $theme_file, using default"
        # shellcheck source=./themes/default.sh
        source "${CURRENT_DIR}/themes/default.sh"
    fi
}
```

---

## 7. エラーハンドリング戦略

### 7.1 エラーレベル

```bash
# エラーレベル定義
readonly ERROR_FATAL=3    # 致命的エラー（プラグイン起動不可）
readonly ERROR_ERROR=2    # エラー（操作失敗、継続可能）
readonly ERROR_WARN=1     # 警告
readonly ERROR_INFO=0     # 情報

# エラーコード定義
readonly ERR_DEPENDENCY=10     # 依存関係不足
readonly ERR_NO_SESSION=20     # セッション不存在
readonly ERR_INVALID_INPUT=30  # 無効な入力
readonly ERR_TMUX_CMD=40       # tmuxコマンド失敗
readonly ERR_FZF_CANCEL=50     # ユーザーキャンセル
```

### 7.2 エラーハンドリングパターン

```bash
# パターン1: 早期リターン
function_with_validation() {
    local input="$1"

    # バリデーション
    if [[ -z "$input" ]]; then
        log_error "Input is empty" "$ERR_INVALID_INPUT"
        return "$ERR_INVALID_INPUT"
    fi

    # 処理
    # ...

    return 0
}

# パターン2: トラップ
setup_error_handlers() {
    trap 'handle_exit $?' EXIT
    trap 'handle_error $? $LINENO' ERR
    trap 'handle_interrupt' INT TERM
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Error at line ${line_number}: exit code ${exit_code}"
}

handle_exit() {
    local exit_code=$1
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with code: $exit_code"
    fi
}

handle_interrupt() {
    log_info "Received interrupt signal"
    cleanup
    exit 130
}

# パターン3: コマンド実行ラッパー
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
```

### 7.3 エラーメッセージ設計

```bash
# エラーメッセージテンプレート
declare -A ERROR_MESSAGES=(
    [$ERR_DEPENDENCY]="Dependencies not met. Please install required packages."
    [$ERR_NO_SESSION]="Session not found: %s"
    [$ERR_INVALID_INPUT]="Invalid input: %s"
    [$ERR_TMUX_CMD]="tmux command failed: %s"
    [$ERR_FZF_CANCEL]="Operation cancelled by user"
)

# エラーメッセージ出力
show_error() {
    local error_code=$1
    shift
    local params=("$@")

    local message="${ERROR_MESSAGES[$error_code]}"

    # パラメータ置換
    for param in "${params[@]}"; do
        message="${message/\%s/$param}"
    done

    # ログ出力
    log_error "$message"

    # tmux表示
    tmux display-message "[Error] $message" 2>/dev/null || true
}
```

---

## 8. テスト実装計画

### 8.1 テスト環境セットアップ

※ テストは`tmux -L session-switcher-test`のような専用ソケットを使い、`test-session-`接頭辞のみを削除することで本番セッションを保護する。

```bash
#!/usr/bin/env bash
# tests/setup-test-env.sh

set -euo pipefail

# テスト用のtmuxセッション作成
setup_test_sessions() {
    local sessions=(
        "test-session-1"
        "test-session-2"
        "test-session-3"
    )

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
}

# テスト環境クリーンアップ
cleanup_test_sessions() {
    local sessions=(
        "test-session-1"
        "test-session-2"
        "test-session-3"
    )

    for session in "${sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            tmux kill-session -t "$session"
        fi
    done

    echo "Test environment cleaned up"
}

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
```

### 8.2 単体テスト

```bash
#!/usr/bin/env bash
# tests/test-session-list.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_DIR="${SCRIPT_DIR}/.."

# テストカウンター
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# アサーション関数
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

# テストケース
test_session_list_output() {
    echo "Running test: session_list_output"

    local output
    output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    assert_not_empty "$output" "session-list.sh should produce output"
    assert_contains "$output" "test-session-1" "Output should contain test-session-1"
    assert_contains "$output" "test-session-2" "Output should contain test-session-2"
    assert_contains "$output" "test-session-3" "Output should contain test-session-3"
}

test_session_list_format() {
    echo "Running test: session_list_format"

    local output
    output=$(bash "${PROJECT_DIR}/scripts/session-list.sh")

    # アイコンの存在確認
    assert_contains "$output" "📝\|📎\|💤" "Output should contain session icons"

    # ウィンドウ数表示の確認
    assert_contains "$output" "\[.*W\]" "Output should show window count"
}

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

# メイン処理
main() {
    echo "================================"
    echo "Testing: session-list.sh"
    echo "================================"
    echo

    # テスト環境セットアップ
    bash "${SCRIPT_DIR}/setup-test-env.sh" setup

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
```

### 8.3 統合テスト

```bash
#!/usr/bin/env bash
# tests/test-integration.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_DIR="${SCRIPT_DIR}/.."

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
        return 1
    fi
    echo "  ✓ Window list generated"

    # 最初のウィンドウindex取得
    local first_window
    first_window=$(echo "$window_list" | head -1 | awk '{print $1}')

    # ペーン一覧取得
    local pane_list
    pane_list=$(bash "${PROJECT_DIR}/scripts/pane-list.sh" "$test_session" "$first_window")

    if [[ -z "$pane_list" ]]; then
        echo "  ✗ FAIL: Pane list is empty"
        return 1
    fi
    echo "  ✓ Pane list generated"

    # クリーンアップ
    bash "${SCRIPT_DIR}/setup-test-env.sh" cleanup

    echo "  ✓ PASS: Hierarchical navigation test"
    return 0
}

# メイン処理
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

    echo "================================"
    if [[ $failed -eq 0 ]]; then
        echo "All integration tests passed!"
        exit 0
    else
        echo "Some integration tests failed: $failed"
        exit 1
    fi
}

main "$@"
```

---

## 9. 実装チェックリスト

### 9.1 Phase 1: 基盤構築

#### ファイル作成
- [ ] scripts/utils.sh
  - [ ] ログ関数（log_debug, log_info, log_warn, log_error）
  - [ ] format_time_ago
  - [ ] get_icon
  - [ ] get_activity_marker
  - [ ] validate_session_name
  - [ ] truncate_string
  - [ ] check_dependencies

- [ ] scripts/config.sh
  - [ ] デフォルト設定定義
  - [ ] tmuxオプション取得
  - [ ] テーマカラー設定
  - [ ] fzfオプション構築関数

- [ ] tmux-session-switcher.tmux
  - [ ] 依存関係チェック
  - [ ] キーバインド登録
  - [ ] 起動メッセージ

#### テスト
- [ ] utils.sh単体テスト
- [ ] config.sh設定読み込みテスト
- [ ] 依存関係チェック動作確認

### 9.2 Phase 2: コア機能実装

#### ファイル作成
- [ ] scripts/session-list.sh
  - [ ] セッション一覧取得
  - [ ] ソート機能
  - [ ] フォーマット処理
  - [ ] カラーリング

- [ ] scripts/preview-session.sh
  - [ ] ヘッダー生成
  - [ ] セッション情報表示
  - [ ] ウィンドウ一覧表示
  - [ ] ペーンプレビュー

- [ ] scripts/session-mode.sh
  - [ ] fzfオプション構築
  - [ ] キーバインド設定
  - [ ] 結果処理
  - [ ] セッション切り替え

- [ ] scripts/switcher.sh
  - [ ] popup起動
  - [ ] エラーハンドリング
  - [ ] フォールバック処理

#### テスト
- [ ] session-list.sh出力確認
- [ ] preview-session.sh描画確認
- [ ] session-mode.sh UI動作確認
- [ ] 統合テスト（セッション選択→切り替え）

### 9.3 Phase 3: 詳細機能実装

#### ファイル作成
- [ ] scripts/window-list.sh
- [ ] scripts/preview-window.sh
- [ ] scripts/detail-mode.sh
- [ ] scripts/pane-list.sh
- [ ] scripts/preview-pane.sh
- [ ] scripts/pane-mode.sh

#### テスト
- [ ] 各リスト生成スクリプトのテスト
- [ ] 各プレビュースクリプトのテスト
- [ ] 階層的ナビゲーションテスト

### 9.4 Phase 4: CRUD操作実装

#### ファイル作成
- [ ] scripts/actions.sh
  - [ ] new（新規作成）
  - [ ] rename（リネーム）
  - [ ] kill（削除）
  - [ ] バリデーション
  - [ ] 安全機構

#### テスト
- [ ] 新規作成テスト
- [ ] リネームテスト
- [ ] 削除テスト
- [ ] エッジケーステスト

### 9.5 Phase 5: テーマとUI改善

#### ファイル作成
- [ ] scripts/themes/tokyonight.sh
- [ ] scripts/themes/catppuccin.sh
- [ ] scripts/themes/default.sh

#### テスト
- [ ] 各テーマの表示確認
- [ ] テーマ切り替え動作確認

### 9.6 Phase 6: テストと最適化

#### タスク
- [ ] 全単体テスト実行
- [ ] 全統合テスト実行
- [ ] パフォーマンス測定
  - [ ] 起動時間
  - [ ] プレビュー生成時間
  - [ ] リスト更新時間
- [ ] メモリ使用量測定（/usr/bin/time -v または time -l でRSS確認）
- [ ] 互換性ログ収集（tmux/bash/fzfのバージョン、Ubuntu+macOS CI）
- [ ] エッジケース対応
  - [ ] 特殊文字を含むセッション名
  - [ ] 大量セッション（100個以上）
  - [ ] 長いセッション名
  - [ ] 最後のセッション削除
- [ ] ドキュメント作成
  - [ ] README.md
  - [ ] ARCHITECTURE.md
  - [ ] DEVELOPMENT.md

### 9.7 最終チェック

- [ ] 全機能動作確認
- [ ] エラーハンドリング確認
- [ ] ログ出力確認
- [ ] パフォーマンス要件達成確認
  - [ ] 起動時間 < 300ms
  - [ ] プレビュー生成 < 500ms
  - [ ] リスト更新 < 200ms
  - [ ] メモリ使用量 < 10MB
- [ ] コード品質チェック
  - [ ] shellcheckエラーなし
  - [ ] コメント充実
  - [ ] 関数分割適切
- [ ] ドキュメント完成度確認

---

## 10. 実装のベストプラクティス

### 10.1 コーディング規約

```bash
# 1. 変数命名
# - グローバル定数: 大文字スネークケース
readonly MAX_SESSION_NAME_LENGTH=50

# - ローカル変数: 小文字スネークケース
local session_name="test"

# - 環境変数: 大文字スネークケース（プレフィックス付き）
export TMUX_SESSION_SWITCHER_DEBUG=0

# 2. 関数命名
# - 動詞で始める
get_session_list() { }
format_session_name() { }
validate_input() { }

# 3. エラーハンドリング
# - 常に戻り値をチェック
if ! command; then
    handle_error
    return 1
fi

# 4. クォート
# - 変数展開は必ずダブルクォート
echo "$variable"

# - 文字列リテラルはシングルクォート
echo 'literal string'

# 5. 配列
# - 配列宣言は明示的に
declare -a array=()

# - 配列展開は適切にクォート
for item in "${array[@]}"; do
    echo "$item"
done
```

### 10.2 パフォーマンス最適化

```bash
# 1. パイプラインの最適化
# Bad: 不要なcat
cat file.txt | grep pattern

# Good: 直接grep
grep pattern file.txt

# 2. 外部コマンドの削減
# Bad: 外部コマンド多用
basename "$path"
dirname "$path"

# Good: bash組み込み機能
filename="${path##*/}"
directory="${path%/*}"

# 3. ループ内でのコマンド実行回避
# Bad: ループ内で重複実行
for item in "${array[@]}"; do
    current_session=$(tmux display-message -p '#S')
    # ...
done

# Good: ループ外で一度だけ実行
current_session=$(tmux display-message -p '#S')
for item in "${array[@]}"; do
    # ...
done

# 4. 並列処理の活用
# 重い処理は並列化
for item in "${items[@]}"; do
    process_item "$item" &
done
wait
```

### 10.3 デバッグテクニック

```bash
# 1. デバッグ出力
if [[ "$DEBUG_MODE" == "1" ]]; then
    set -x  # コマンドトレース有効化
fi

# 2. チェックポイント
debug_checkpoint() {
    local message="$1"
    log_debug "CHECKPOINT: $message"
}

# 3. 変数ダンプ
dump_variables() {
    log_debug "SESSION_NAME: $SESSION_NAME"
    log_debug "WINDOW_INDEX: $WINDOW_INDEX"
    log_debug "PANE_INDEX: $PANE_INDEX"
}

# 4. エラー発生箇所の特定
trap 'echo "Error at line $LINENO"' ERR
```

---

## 付録: 実装サンプルスニペット

### A.1 完全な関数実装例

```bash
# window-list.sh の完全実装サンプル
get_window_layout_icon() {
    local panes="$1"
    local layout="$2"

    if [[ $panes -eq 1 ]]; then
        echo "▢"  # 単一ペーン
    elif [[ "$layout" =~ "," ]]; then
        # レイアウト文字列から分割方向を判定
        if [[ "$layout" =~ "[0-9]+x[0-9]+,[0-9]+,[0-9]+" ]]; then
            echo "⊞"  # 複数ペーン（複雑）
        else
            echo "⊟"  # 2分割
        fi
    else
        echo "⊞"  # デフォルト
    fi
}
```

### A.2 テストヘルパー関数

```bash
# tests/test-helpers.sh

# テスト用セッション作成
create_test_session() {
    local name="$1"
    local windows="${2:-1}"

    tmux new-session -d -s "$name"

    for ((i=1; i<windows; i++)); do
        tmux new-window -t "${name}:${i}"
    done
}

# テスト用セッション削除
cleanup_test_session() {
    local name="$1"

    if tmux has-session -t "$name" 2>/dev/null; then
        tmux kill-session -t "$name"
    fi
}

# アサーション: 文字列比較
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $message"
        return 0
    else
        echo "✗ FAIL: $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}
```

---

## 改訂履歴

| バージョン | 日付 | 変更内容 | 担当者 |
|-----------|------|---------|--------|
| 1.0 | 2025-11-12 | 初版作成 | - |

---

**次のステップ:**
1. Phase 1の実装開始（utils.sh, config.sh）
2. 単体テストの作成
3. Phase 2への移行

この詳細設計書に従って、段階的に実装を進めることで、高品質なtmuxプラグインを効率的に開発できます。
