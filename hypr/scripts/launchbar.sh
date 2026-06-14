#!/usr/bin/env bash

exec 200>/tmp/bar-launch.lock
flock -n 200 || exit 0

killall quickshell || true
pkill quickshell || true
killall qs || true
pkill qs || true
sleep 0.5

# Check if bar-disabled file exists
if [ ! -f "$HOME/.config/hypr/scripts/bardisabled" ]; then
    qs &
else
    echo ":: Bar disabled"
fi

flock -u 200
exec 200>&-
