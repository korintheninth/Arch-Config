sel=$(locate -i "" | rofi -dmenu -i -theme-str 'entry { placeholder: "Search Files"; }')
[ -z "$sel" ] && exit

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
