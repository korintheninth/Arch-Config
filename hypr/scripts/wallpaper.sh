#!/usr/bin/env bash
#  _      __     ____
# | | /| / /__ _/ / /__  ___ ____  ___ ____
# | |/ |/ / _ `/ / / _ \/ _ `/ _ \/ -_) __/
# |__/|__/\_,_/_/_/ .__/\_,_/ .__/\__/_/
#                /_/       /_/

# -----------------------------------------------------
# Set defaults
# -----------------------------------------------------

cache_folder="$HOME/.cache/hyprland-dotfiles"

_writeLog() {
    m=$1
    echo ":: $m"
}

force_generate=0

# Cache for generated wallpapers with effects
generatedversions="$cache_folder/wallpaper-generated"
if [ ! -d $generatedversions ]; then
  mkdir -p $generatedversions
fi

# Will be set when waypaper is running
waypaperrunning=$cache_folder/waypaper-running
if [ -f $waypaperrunning ]; then
  rm $waypaperrunning
  exit
fi

blurredwallpaper="$cache_folder/blurred_wallpaper.png"
squarewallpaper="$cache_folder/square_wallpaper.png"
rasifile="$cache_folder/current_wallpaper.rasi"
blur="50x30"

# -----------------------------------------------------
# Get selected wallpaper
# -----------------------------------------------------

wallpaper=$1

used_wallpaper=$wallpaper
_writeLog "Setting wallpaper with source image $wallpaper"
tmpwallpaper=$wallpaper

# -----------------------------------------------------
# Get wallpaper filename
# -----------------------------------------------------

wallpaperfilename=$(basename $wallpaper)
_writeLog "Wallpaper Filename: $wallpaperfilename"

# -----------------------------------------------------
# Execute matugen
# -----------------------------------------------------

$HOME/.local/bin/matugen image $used_wallpaper -m "dark"

$HOME/.config/hypr/scripts/update_colors.sh $used_wallpaper

# -----------------------------------------------------
# Reload Waybar
# -----------------------------------------------------

sleep 1
$HOME/.config/waybar/launch.sh

# -----------------------------------------------------
# Reload nwg-dock-hyprland
# -----------------------------------------------------

$HOME/.config/nwg-dock-hyprland/launch.sh &

# -----------------------------------------------------
# Update SwayNC
# -----------------------------------------------------

sleep 0.1
swaync-client -rs

# -----------------------------------------------------
# Created blurred wallpaper
# -----------------------------------------------------

if [ -f ~/.config/settings/wallpaper_cache ]; then
  use_cache=1
  _writeLog "Using Wallpaper Cache"
else
  use_cache=0
  _writeLog "Wallpaper Cache disabled"
fi

if [ -f $generatedversions/blur-$blur-$effect-$wallpaperfilename.png ] && [ "$force_generate" == "0" ] && [ "$use_cache" == "1" ]; then
  _writeLog "Use cached wallpaper blur-$blur-$effect-$wallpaperfilename"
else
  _writeLog "Generate new cached wallpaper blur-$blur-$effect-$wallpaperfilename with blur $blur"
  # notify-send --replace-id=1 "Generate new blurred version" "with blur $blur" -h int:value:66
  magick $used_wallpaper -resize 75% $blurredwallpaper
  _writeLog "Resized to 75%"
  if [ ! "$blur" == "0x0" ]; then
    magick $blurredwallpaper -blur $blur $blurredwallpaper
    cp $blurredwallpaper $generatedversions/blur-$blur-$effect-$wallpaperfilename.png
    _writeLog "Blurred"
  fi
fi
cp $generatedversions/blur-$blur-$effect-$wallpaperfilename.png $blurredwallpaper

# -----------------------------------------------------
# Create rasi file
# -----------------------------------------------------

if [ ! -f $rasifile ]; then
  touch $rasifile
fi
echo "* { current-image: url(\"$blurredwallpaper\", height); }" >"$rasifile"

# -----------------------------------------------------
# Created square wallpaper
# -----------------------------------------------------

_writeLog "Generate new cached wallpaper square-$wallpaperfilename"
magick $tmpwallpaper -gravity Center -extent 1:1 $squarewallpaper
cp $squarewallpaper $generatedversions/square-$wallpaperfilename.png
