#!/bin/bash
brightness=$(ddcutil --disable-dynamic-sleep --display 1 getvcp 10 2>/dev/null | \
        awk 'match($0, /current value[[:space:]]*=[[:space:]]*([^,]+)/, a) { print a[1]; exit }')

echo "$brightness"
