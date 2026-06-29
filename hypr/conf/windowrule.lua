-- Pavucontrol float oning
hl.window_rule({
    match = {
        class = "(.*org.pulseaudio.pavucontrol.*)",
    },
    float = true,
    size = "700 600",
    center = true,
})

-- Waypaper
hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    float = true,
    size = "1800 1000",
    center = true,
})

-- General floating
hl.window_rule({
    match = {
        class = "(dotfiles-floating)",
    },
    float = true,
    size = "1000 700",
    center = true,
})

-- General floating
hl.window_rule({
    match = {
        class = "(floating)",
    },
    float = true,
    center = true,
})

-- Blueman Manager
hl.window_rule({
    match = {
        class = "(blueman-manager)",
    },
    float = true,
    size = "800 600",
    center = true,
})

-- Gnome Calculator
hl.window_rule({
    match = {
        class = "(org.gnome.Calculator)",
    },
    float = true,
    center = true,
    size = "700 600",
})

-- Hyprland Share Picker
hl.window_rule({
    match = {
        class = "(hyprland-share-picker)",
    },
    float = true,
    pin = true,
    center = true,
    size = "600 400",
})

-- float on and center on file pickers
hl.window_rule({
    match = {
        class = "xdg-desktop-portal-gtk",
        title = "^(Open.*Files?|Save.*Files?|All Files|Save)",
    },
    float = true,
    center = true,
    float = true,
})

hl.window_rule({
    match = {
        class = "paradox-launcher-v2",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(steam)$",
        title = "^(steam)$",
    },
    tile = true,
})

-- Browser Picture in Picture
hl.window_rule({
    match = {
        title = "^(Picture-in-Picture)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        title = "^(Picture-in-Picture)$",
    },
    pin = true,
    move = "69.5% 4%",
})

-- idleinhibit
hl.window_rule({
    match = {
        class = "([window])",
    },
    idle_inhibit = "fullscreen",
})
hl.window_rule({
    name = "keep-unity-rendering",
    match = {
        class = "^(Unity)$",
    },
    render_unfocused = true,
})

hl.window_rule({
    match = {
        class = "^(com.github.th-ch.youtube-music)$",
    },
    float = true,
    size = "1200 700",
    center = true,
})

hl.window_rule({
    match = {
        class = "^(com.configmenu.ConfigMenu)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(io.missioncenter.MissionCenter)$",
    },
    float = true,
    center = true,
    size = "850 425",
})

hl.window_rule({
    match = {
        class = "org.gnome.baobab",
    },
    float = true,
})
