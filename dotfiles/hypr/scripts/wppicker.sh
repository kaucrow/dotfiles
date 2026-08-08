#!/bin/bash

# === CONFIG ===
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
ROFI_WALLPAPER_PATH="$HOME/.config/hypr/rofi_wallpaper"

cd "$WALLPAPER_DIR" || exit 1

# === handle spaces name
IFS=$'\n'

# === ICON-PREVIEW SELECTION WITH ROFI, SORTED BY NEWEST ===
SELECTED_WALL=$(for a in $(ls -t *.jpg *.png *.gif *.jpeg 2>/dev/null); do echo -en "$a\0icon\x1f$a\n"; done | ~/.config/rofi/launcher/dmenulauncher.sh)
[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === SET WALLPAPER ===
#matugen image "$SELECTED_PATH"
kitty --class="matugen-picker" -e matugen -m dark -t scheme-content image "$SELECTED_PATH"
sleep 0.5

# === CREATE SYMLINK ===
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# === CREATE ROFI DOWNSCALED WALLPAPER ===
magick ~/.config/hypr/current_wallpaper -resize 800x800^ -quality 60 "$ROFI_WALLPAPER_PATH"
