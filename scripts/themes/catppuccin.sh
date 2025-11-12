#!/usr/bin/env bash
# ファイル名: catppuccin.sh
# 説明: Catppuccin カラーテーマ
# 依存: なし

# Catppuccin (Mocha) カラーパレット
declare -A CATPPUCCIN_COLORS=(
    # 背景・前景
    [bg]="#1e1e2e"
    [bg_plus]="#313244"
    [fg]="#cdd6f4"
    [fg_plus]="#cdd6f4"

    # ボーダー
    [border]="#89b4fa"

    # ハイライト
    [hl]="#89b4fa"
    [hl_plus]="#94e2d5"

    # UI要素
    [info]="#89b4fa"
    [prompt]="#94e2d5"
    [pointer]="#f38ba8"
    [marker]="#a6e3a1"
    [spinner]="#a6e3a1"
    [header]="#a6e3a1"
)

# fzf用カラー文字列
THEME_FZF_COLORS="--color=bg+:${CATPPUCCIN_COLORS[bg_plus]},bg:${CATPPUCCIN_COLORS[bg]},border:${CATPPUCCIN_COLORS[border]},fg:${CATPPUCCIN_COLORS[fg]},fg+:${CATPPUCCIN_COLORS[fg_plus]},hl:${CATPPUCCIN_COLORS[hl]},hl+:${CATPPUCCIN_COLORS[hl_plus]},info:${CATPPUCCIN_COLORS[info]},prompt:${CATPPUCCIN_COLORS[prompt]},pointer:${CATPPUCCIN_COLORS[pointer]},marker:${CATPPUCCIN_COLORS[marker]},spinner:${CATPPUCCIN_COLORS[spinner]},header:${CATPPUCCIN_COLORS[header]}"
