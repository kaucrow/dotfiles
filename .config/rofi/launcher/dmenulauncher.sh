#!/usr/bin/env bash
dir="$HOME/.config/rofi/launcher"
theme='config'

## run
rofi \
    -dmenu -p "" \
    -theme ${dir}/${theme}.rasi
