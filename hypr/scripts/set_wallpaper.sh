# -----------------------------------------------------
# Create cache folder
# -----------------------------------------------------
cache_folder="$HOME/.cache/hyprland-dotfiles"

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
cachefile="$cache_folder/current_wallpaper"
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

$HOME/.config/hypr/scripts/wallpaper.sh "$tmpwallpaper"
