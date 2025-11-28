#!/usr/bin/env bash
# File: catppuccin.sh
# Description: Catppuccin color theme
# Dependencies: none

# Catppuccin (Mocha) palette
declare -A CATPPUCCIN_COLORS=(
    # Background / foreground
    [bg]="#1e1e2e"
    [bg_plus]="#313244"
    [fg]="#cdd6f4"
    [fg_plus]="#cdd6f4"

    # Border
    [border]="#89b4fa"

    # Highlight
    [hl]="#89b4fa"
    [hl_plus]="#94e2d5"

    # UI accents
    [info]="#89b4fa"
    [prompt]="#94e2d5"
    [pointer]="#f38ba8"
    [marker]="#a6e3a1"
    [spinner]="#a6e3a1"
    [header]="#a6e3a1"
)

# fzf color string
THEME_FZF_COLORS="--color=bg+:${CATPPUCCIN_COLORS[bg_plus]},bg:${CATPPUCCIN_COLORS[bg]},border:${CATPPUCCIN_COLORS[border]},fg:${CATPPUCCIN_COLORS[fg]},fg+:${CATPPUCCIN_COLORS[fg_plus]},hl:${CATPPUCCIN_COLORS[hl]},hl+:${CATPPUCCIN_COLORS[hl_plus]},info:${CATPPUCCIN_COLORS[info]},prompt:${CATPPUCCIN_COLORS[prompt]},pointer:${CATPPUCCIN_COLORS[pointer]},marker:${CATPPUCCIN_COLORS[marker]},spinner:${CATPPUCCIN_COLORS[spinner]},header:${CATPPUCCIN_COLORS[header]}"
