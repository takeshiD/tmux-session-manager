#!/usr/bin/env bash
# ファイル名: tokyonight.sh
# 説明: Tokyo Night カラーテーマ
# 依存: なし

# Tokyo Night カラーパレット
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

# fzf用カラー文字列
THEME_FZF_COLORS="--color=bg+:${TOKYONIGHT_COLORS[bg_plus]},bg:${TOKYONIGHT_COLORS[bg]},border:${TOKYONIGHT_COLORS[border]},fg:${TOKYONIGHT_COLORS[fg]},fg+:${TOKYONIGHT_COLORS[fg_plus]},hl:${TOKYONIGHT_COLORS[hl]},hl+:${TOKYONIGHT_COLORS[hl_plus]},info:${TOKYONIGHT_COLORS[info]},prompt:${TOKYONIGHT_COLORS[prompt]},pointer:${TOKYONIGHT_COLORS[pointer]},marker:${TOKYONIGHT_COLORS[marker]},spinner:${TOKYONIGHT_COLORS[spinner]},header:${TOKYONIGHT_COLORS[header]}"
