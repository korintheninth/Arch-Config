#!/usr/bin/env bash
#  _      __     ____
# | | /| / /__ _/ / /__  ___ ____  ___ ____
# | |/ |/ / _ `/ / / _ \/ _ `/ _ \/ -_) __/
# |__/|__/\_,_/_/_/ .__/\_,_/ .__/\__/_/
#                /_/       /_/

export PATH="/home/korin/.local/bin:/usr/bin:/usr/local/bin"
# -----------------------------------------------------
# Create cache folder
# -----------------------------------------------------
cache_folder="$HOME/.cache/hyprland-dotfiles"
cachefile="$cache_folder/current_wallpaper"

_writeLog() {
    m=$1
    echo ":: $m"
}

if [ -z "$1" ]; then
  if [ -f "$cachefile" ]; then
    wallpaper=$(cat "$cachefile")
  else
    wallpaper=$defaultwallpaper
  fi
else
  wallpaper=$1
fi

if [ ! -d $cache_folder ]; then
  mkdir -p $cache_folder
fi
if [ ! -f "$cachefile" ]; then
  touch "$cachefile"
fi
echo "$wallpaper" >"$cachefile"

_writeLog "$wallpaper"

wallpaperfilename=$(basename "$wallpaper")

# Default tmpwallpaper to original wallpaper
tmpwallpaper="$wallpaper"

# Determine if wallpaper is GIF or video for frame extraction
filetype=$(file --mime-type -b "$wallpaper")

if [[ $filetype == *gif* ]]; then
  # For animated GIFs, extract first frame
  tmpwallpaper="${cache_folder}/first-frame-${wallpaperfilename%.*}.png"
  magick convert "${wallpaper}[0]" "$tmpwallpaper"
elif [[ $filetype == *video* ]]; then
  # For videos, extract first frame using ffmpeg
  tmpwallpaper="${cache_folder}/first-frame-${wallpaperfilename%.*}.png"
  ffmpeg -y -i "$wallpaper" -frames:v 1 "$tmpwallpaper" -loglevel error
fi

rasifile="$cache_folder/current_wallpaper.rasi"

# -----------------------------------------------------
# Get selected wallpaper
# -----------------------------------------------------

used_wallpaper=$tmpwallpaper

# -----------------------------------------------------
# Get wallpaper filename
# -----------------------------------------------------

wallpaperfilename=$(basename $tmpwallpaper)
_writeLog "Wallpaper Filename: $wallpaperfilename"

# -----------------------------------------------------
# Execute matugen and wallust
# -----------------------------------------------------

$HOME/.local/bin/matugen image $used_wallpaper -m "dark" --type scheme-fidelity

wallust run $used_wallpaper

pkill -SIGUSR1 kitty

cp $used_wallpaper $cache_folder/current_wallpaper.png

# -----------------------------------------------------
# Update keyboard
# -----------------------------------------------------

python /home/korin/.config/hypr/scripts/set_keyboard_colors.py

