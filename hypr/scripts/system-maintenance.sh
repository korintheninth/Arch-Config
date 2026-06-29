#!/usr/bin/env bash
# arch-maintenance.sh
# Safely automates routine Arch Linux cleanup tasks.

echo "Starting routine Arch Linux maintenance..."

# 1. Clean the pacman cache (keeping the 2 most recent versions)
echo -e "\n>> Cleaning pacman cache..."
if command -v paccache &> /dev/null; then
    sudo paccache -rk2
else
    echo "paccache not found. (Install pacman-contrib for better cache management)."
    sudo pacman -Sc --noconfirm
fi

# 2. Clean the yay cache (removes uninstalled package caches)
if command -v yay &> /dev/null; then
    echo -e "\n>> Cleaning yay cache..."
    yay -Sc --noconfirm
fi

# 3. Remove orphaned packages safely
echo -e "\n>> Checking for orphaned packages..."
# Get a list of orphans quietly
ORPHANS=$(pacman -Qdtq)

if [ -n "$ORPHANS" ]; then
    echo "Removing orphaned packages..."
    sudo pacman -Rns $ORPHANS --noconfirm
else
    echo "No orphans found."
fi

# 4. Check for failed systemd services
echo -e "\n>> Checking systemd health..."
FAILED_SERVICES=$(systemctl --failed --quiet)

if [ -z "$FAILED_SERVICES" ]; then
    echo "All systemd services are running flawlessly."
else
    echo "WARNING: The following systemd services have failed:"
    systemctl --failed
fi

# 5. Reminders for manual tasks
echo -e "\n=== MANUAL TASKS REMINDER ==="
echo "1. Remember to run 'sudo pacdiff' occasionally to merge .pacnew files."
echo "2. Always check archlinux.org before your next 'yay -Syu'."
echo "Maintenance complete!"
