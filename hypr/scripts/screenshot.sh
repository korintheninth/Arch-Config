#!/usr/bin/env bash

# Screenshot Filename
NAME="screenshot_$(date +%d%m%Y_%H%M%S).jpg"

# Screenshot Folder
screenshot_folder="$HOME/Pictures"

# Quick instant mode: full screen
take_instant_full() {
    grimblast --notify "copysave" "screen" $NAME
    [[ -f "$HOME/$NAME" && -d "$screenshot_folder" && -w "$screenshot_folder" ]] && mv "$HOME/$NAME" "$screenshot_folder/"
}

# Quick instant mode: area selection
take_instant_area() {
    # capture and notify
    grimblast --notify "copysave" "area" $NAME
    [[ -f "$HOME/$NAME" && -d "$screenshot_folder" && -w "$screenshot_folder" ]] && mv "$HOME/$NAME" "$screenshot_folder/"
}

# Handle instant flags
if [[ "$1" == "--instant" ]]; then
    take_instant_full
    exit 0
elif [[ "$1" == "--instant-area" ]]; then
    take_instant_area
    exit 0
fi

