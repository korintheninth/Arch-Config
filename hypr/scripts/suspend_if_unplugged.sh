
if [[ "$(cat /sys/class/power_supply/BAT0/status)" != "Full" && \
      "$(cat /sys/class/power_supply/BAT0/status)" != "Charging" ]]; then
    systemctl suspend
fi
