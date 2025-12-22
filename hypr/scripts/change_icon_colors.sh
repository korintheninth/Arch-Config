#!/usr/bin/env bash
term="color3"
file="$HOME/.config/waybar/colors.css"

color=$(grep -oP "(?<=\b$term\s)[^;\s]+" "$file" | head -n 1)

input=$HOME/.config/waybar/icons/base_assets/arch.svg
output=$HOME/.config/waybar/icons/arch.svg

sed -E "s/(fill=)['\"]#[0-9a-fA-F]{3,6}['\"]/fill=\"${color}\"/g" $input > $output
