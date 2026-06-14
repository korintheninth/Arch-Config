// Match GTK/Waybar icon theme (see ~/.config/gtk-3.0/settings.ini)
//@ pragma IconTheme Papirus
//@ pragma UseQApplication

import Quickshell
import QtQuick
import "modules"

ShellRoot {
    id: root
    Topbar {}
    NotificationPopup {}
    Wallpaper {}
}
