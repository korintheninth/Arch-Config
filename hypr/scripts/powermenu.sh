#!/usr/bin/env bash

POWER="$HOME/.config/hypr/scripts/power.sh"
ICONS="$HOME/.config/rofi/icons"

choice=$(
    for entry in lock logout suspend hibernate reboot shutdown; do
        # Removed "thumbnail://" - Rofi just needs the absolute path
        printf '%s\0icon\x1f%s/%s.png\n' "$entry" "$ICONS" "$entry"
    done | rofi -dmenu -show-icons -config ~/.config/rofi/config-powermenu.rasi
)

case "$choice" in
    lock)      "$POWER" lock ;;
    logout)    "$POWER" exit ;;
    suspend)   "$POWER" suspend ;;
    hibernate) "$POWER" hibernate ;;
    reboot)    "$POWER" reboot ;;
    shutdown)  "$POWER" shutdown ;;
esac