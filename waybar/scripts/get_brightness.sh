#!/bin/bash

last_brightness=""

while true; do
    brightness=$(ddcutil --display 1 getvcp 10 2>/dev/null | \
        awk 'match($0, /current value[[:space:]]*=[[:space:]]*([^,]+)/, a) { print a[1]; exit }')

    if [[ "$brightness" != "$last_brightness" && -n "$brightness" ]]; then
        echo "{\"percentage\": $brightness}"
        last_brightness=$brightness
    fi

    sleep 0.5
done
