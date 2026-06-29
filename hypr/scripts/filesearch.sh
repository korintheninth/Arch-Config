#!/bin/bash

# Create a temporary file to hold the paths and ensure it deletes on exit
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# 1. locate streams paths
# 2. First awk filters out empty names
# 3. tee instantly writes the absolute path to tmpfile AND passes it down the pipe
# 4. Second awk formats it for Rofi
# 5. rofi displays it asynchronously and outputs the 0-based index (-format 'i')
idx=$(locate -i "" | awk -F/ '$NF != ""' | tee "$tmpfile" | awk -F/ '{
    filename = $NF
    dir = substr($0, 1, length($0) - length(filename))
    
    total_max = 38
    
    allowed_dir_len = total_max - length(filename)
    if (allowed_dir_len < 5) allowed_dir_len = 5
    
    if (length(dir) > allowed_dir_len) {
        dir = "..." substr(dir, length(dir) - allowed_dir_len + 4)
    }
    
    gsub(/&/, "&amp;", filename); gsub(/</, "&lt;", filename); gsub(/>/, "&gt;", filename)
    gsub(/&/, "&amp;", dir); gsub(/</, "&lt;", dir); gsub(/>/, "&gt;", dir)
    
    disp_text = dir filename
    
    printf "%s\0display\x1f%s\n", filename, disp_text
    
}' | rofi -dmenu -config ~/.config/rofi/config-compact.rasi -i -markup-rows -format 'i' -theme-str 'entry { placeholder: "Search Files"; }')

# If Escape was pressed or nothing was selected, exit cleanly
if [[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]]; then
    exit
fi

# Extract the exact absolute path from the temp file using the index!
# (Rofi index starts at 0, awk line numbers start at 1)
sel=$(awk "NR == $idx + 1 {print; exit}" "$tmpfile")

[ -z "$sel" ] && exit

# Open the selected file
if [ -d "$sel" ]; then
    xdg-open "$sel"
else
    case "${sel##*.}" in
        jpg|jpeg|png|webp|gif|bmp|svg|mp4|mkv|avi|mov|webm)
            xdg-open "$sel"
            ;;
        *)
            kitty nvim "$sel"
            ;;
    esac
fi
