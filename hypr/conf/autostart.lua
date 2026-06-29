hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/launchbar.sh")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/bin/kdeconnectd")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("gromit-mpx")
end)
