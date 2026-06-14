-- ___       __           __           __

-- / _ |__ __/ /____  ___ / /____ _____/ /_

-- / __ / // / __/ _ \(_-</ __/ _ `/ __/ __/

-- /_/ |_\_,_/\__/\___/___/\__/\_,_/_/  \__/

--

-- Start Polkit
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)

-- Load Wallpaper
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh")
end)

-- Start quickshell
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/launchbar.sh")
end)

-- Using hypridle to start hyprlock
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
end)

-- Load cliphist history
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
end)

-- start pear desktop
hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c \"sleep 1 && pear-desktop --enable-features=UseOzonePlatform --ozone-platform=wayland &\"")
    hl.exec_cmd("/usr/bin/kdeconnectd")
end)
