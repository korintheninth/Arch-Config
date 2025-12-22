#!/bin/bash

brightness_file="${HOME}/.config/hypr/scripts/get_brightness.sh"

current_brightness=$(bash "$brightness_file")

# Add 10, but don't exceed 100
new_brightness=$(( current_brightness - 10 ))

# Set brightness (all displays, remove --display 1 for auto-detect)
ddcutil --disable-dynamic-sleep --display 1 setvcp 10 $new_brightness
