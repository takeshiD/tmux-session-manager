# tmux Session Manager

tmuxのセッション管理を視覚的かつ効率的に行うためのプラグイン。lazygitのようなポップアップUIを提供し、セッション・ウィンドウ・ペーンの階層的なナビゲーションとリアルタイムプレビューを実現します。

## 特徴

- 📝 **視覚的なセッション一覧**: アイコンと色分けで状態を直感的に表示
- 🔍 **リアルタイムプレビュー**: セッション内容をその場で確認
- ⚡ **高速切り替え**: fzfベースの快適な操作性
- 🎨 **カスタマイズ可能**: Tokyo Night、Catppuccinなど複数のテーマ対応
- 📊 **階層的ナビゲーション**: セッション→ウィンドウ→ペーンの3階層移動（実装予定）

## 必要要件

- tmux 3.2以上（popup機能必須）
- fzf 0.30.0以上
- bash 4.0以上

## インストール

### TPM（Tmux Plugin Manager）を使用

`.tmux.conf`に以下を追加：

```tmux
set -g @plugin 'your-name/tmux-session-manager'
```

tmux内で`prefix + I`を実行してインストール。

### 手動インストール

```bash
git clone https://github.com/your-name/tmux-session-manager.git \
    ~/.tmux/plugins/tmux-session-manager
```

`.tmux.conf`に以下を追加：

```tmux
run-shell ~/.tmux/plugins/tmux-session-manager/tmux-session-manager.tmux
```

設定を再読み込み：

```bash
tmux source-file ~/.tmux.conf
```

## 使い方

### 基本操作

デフォルトでは`Ctrl-s`でセッションスイッチャーを起動します。

**セッション一覧モード:**
- `Enter`: セッション切り替え
- `Space`: ウィンドウ詳細モードへ
- `Ctrl-n`: 新規セッション作成
- `Ctrl-r`: セッション名変更
- `Ctrl-x`: セッション削除
- `Ctrl-/`: プレビュー表示/非表示
- `q`: 終了

**ウィンドウ詳細モード:**
- `Enter`: ウィンドウ切り替え
- `Space`: ペーン詳細モードへ
- `ESC`: セッション一覧へ戻る
- `Ctrl-/`: プレビュー表示/非表示
- `q`: 終了

**ペーン詳細モード:**
- `Enter`: ペーン切り替え
- `ESC`: ウィンドウ詳細へ戻る
- `Ctrl-/`: プレビュー表示/非表示
- `q`: 終了

### 設定

`.tmux.conf`で以下の設定が可能です：

```tmux
# キーバインド変更
set -g @session-manager-key 'C-j'

# テーマ変更
set -g @session-manager-theme 'catppuccin'

# ポップアップサイズ調整
set -g @session-manager-popup-width '80%'
set -g @session-manager-popup-height '70%'

# プレビューウィンドウ幅
set -g @session-manager-preview-width '65'

# デバッグモード
set -g @session-manager-debug '1'
```

## 利用可能なテーマ

- `tokyonight` (デフォルト)
- `catppuccin`
- `default` (tmuxのデフォルトカラー)

## アイコンの意味

- 📝 緑: 現在のセッション
- 📎 黄: アタッチ済みセッション
- 💤 グレー: デタッチセッション

## 活動マーカー

- 🔥: 5分以内に活動
- ⚡: 1時間以内に活動

## 開発状況

### 実装済み機能

- ✅ Phase 1: 基盤構築（utils.sh, config.sh, プラグインエントリー）
- ✅ Phase 2: コア機能（セッション一覧、プレビュー、基本切り替え）
- ✅ Phase 3: 詳細機能（ウィンドウ・ペーンレベルの操作）
- ✅ Phase 4: CRUD操作（セッション作成・削除・リネーム）
- ✅ Phase 5: テーマシステム（Tokyo Night, Catppuccin, Default）

### 実装予定機能

- ⏳ Phase 6: テストと最適化（単体テスト、統合テスト、パフォーマンス測定）

## トラブルシューティング

### ポップアップが表示されない

tmuxのバージョンを確認してください：

```bash
tmux -V  # 3.2以上が必要
```

### fzfが見つからない

fzfをインストールしてください：

```bash
# macOS
brew install fzf

# Ubuntu
sudo apt install fzf
```

## ライセンス

MIT License

## 関連リンク

- [tmux公式](https://github.com/tmux/tmux)
- [fzf](https://github.com/junegunn/fzf)

## 作者

tmux-session-manager開発チーム
