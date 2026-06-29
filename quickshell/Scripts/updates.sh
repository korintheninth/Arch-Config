#!/usr/bin/env bash
#  _   _            _       _              
# | | | |_ __   __| | __ _| |_ ___  ___  
# | | | | '_ \ / _` |/ _` | __/ _ \/ __| 
# | |_| | |_) | (_| | (_| | ||  __/\__ \ 
#  \___/| .__/ \__,_|\__,_|\__\___||___/ 
#       |_|                              
#  

# ----------------------------------------------------- 
# Prevent concurrent executions using flock
# ----------------------------------------------------- 
exec 9>/tmp/waybar-update-checker.lock
if ! flock -n 9; then
    exit 0
fi

# ----------------------------------------------------- 
# Helper Functions
# ----------------------------------------------------- 
_checkCommandExists() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo 1
    else
        echo 0
    fi
}

check_lock_files() {
    local pacman_lock="/var/lib/pacman/db.lck"
    local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"

    while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
        sleep 1
    done
}

# ----------------------------------------------------- 
# Define thresholds for color indicators
# ----------------------------------------------------- 
threshold_green=0
threshold_yellow=100
threshold_red=400

# ----------------------------------------------------- 
# Check for updates
# ----------------------------------------------------- 
updates=0

if [[ $(_checkCommandExists "pacman") == 0 ]]; then
    check_lock_files
    
    # 1. Try the custom wrapper first
    if [[ $(_checkCommandExists "checkupdates-with-aur") == 0 ]]; then
        updates=$(checkupdates-with-aur 2>/dev/null | wc -l)
        
    # 2. Fallback: Manual check using official repos + paru (or yay)
    else
        repo_updates=$(checkupdates 2>/dev/null | wc -l)
        aur_updates=0
        
        if [[ $(_checkCommandExists "paru") == 0 ]]; then
            aur_updates=$(paru -Qua 2>/dev/null | wc -l)
        elif [[ $(_checkCommandExists "yay") == 0 ]]; then
            aur_updates=$(yay -Qua 2>/dev/null | wc -l)
        fi
        
        updates=$((repo_updates + aur_updates))
    fi
fi

echo "$updates"
