#!/usr/bin/env bash
export PATH="/home/korin/.local/bin:/usr/bin:/usr/local/bin"
wallust run --backend full --check-contrast $1
pkill -SIGUSR1 kitty
$HOME/.config/hypr/scripts/change_icon_colors.sh
