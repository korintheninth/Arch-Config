-- -----------------------------------------------------

-- Window rules

-- -----------------------------------------------------
hl.window_rule({
    match = {
        title = "^(pavucontrol)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        title = "^(blueman-manager)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        title = "^(nm-connection-editor)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        title = "^(qalculate-gtk)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "org.gnome.baobab",
    },
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
})
hl.window_rule({
    match = {
        title = "^(Picture-in-Picture)$",
    },
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
        class = "^(com.github.th_ch.youtube_music)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "^(com.github.th_ch.youtube_music)$",
    },
    size = "850 425",
})
hl.window_rule({
    match = {
        class = "^(pear-desktop)$",
    },
    center = true,
})
hl.window_rule({
    match = {
        class = "^(io.missioncenter.MissionCenter)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "^(io.missioncenter.MissionCenter)$",
    },
    size = "850 425",
})
hl.window_rule({
    match = {
        class = "^(io.missioncenter.MissionCenter)$",
    },
    center = true,
})
