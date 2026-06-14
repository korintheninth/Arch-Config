if [ -f $HOME/.config/hypr/scripts/bardisabled ]; then
    rm $HOME/.config/hypr/scripts/bardisabled
else
    touch $HOME/.config/hypr/scripts/bardisabled
fi
$HOME/.config/hypr/scripts/launchbar.sh &
