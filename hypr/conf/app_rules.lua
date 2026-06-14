-- Pavucontrol float oning
hl.window_rule({
    match = {
        class = "(.*org.pulseaudio.pavucontrol.*)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(.*org.pulseaudio.pavucontrol.*)",
    },
    size = "700 600",
})
hl.window_rule({
    match = {
        class = "(.*org.pulseaudio.pavucontrol.*)",
    },
    center = true,
})
hl.window_rule({
    match = {
        class = "(.*org.pulseaudio.pavucontrol.*)",
    },
    pin = true,
})

-- Waypaper
hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    size = "900 700",
})
hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    center = true,
})
hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    pin = true,
})

-- Blueman Manager
hl.window_rule({
    match = {
        class = "(blueman-manager)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(blueman-manager)",
    },
    size = "800 600",
})
hl.window_rule({
    match = {
        class = "(blueman-manager)",
    },
    center = true,
})

-- System Mission center on
hl.window_rule({
    match = {
        class = "(io.missioncenter on.MissionCenter)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(io.missioncenter on.MissionCenter)",
    },
    pin = true,
})
hl.window_rule({
    match = {
        class = "(io.missioncenter.MissionCenter)",
    },
    center = true,
})
hl.window_rule({
    match = {
        class = "(io.missioncenter on.MissionCenter)",
    },
    size = "900 600",
})

-- System Mission center on Preference Window
hl.window_rule({
    match = {
        class = "(missioncenter on)",
        title = "^(Preferences)$",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(missioncenter on)",
        title = "^(Preferences)$",
    },
    pin = true,
})
hl.window_rule({
    match = {
        class = "(missioncenter)",
        title = "^(Preferences)$",
    },
    center = true,
})

-- Gnome Calculator
hl.window_rule({
    match = {
        class = "(org.gnome.Calculator)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(org.gnome.Calculator)",
    },
    size = "700 600",
})
hl.window_rule({
    match = {
        class = "(org.gnome.Calculator)",
    },
    center = true,
})

-- Hyprland Share Picker
hl.window_rule({
    match = {
        class = "(hyprland-share-picker)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "(hyprland-share-picker)",
    },
    pin = true,
})
hl.window_rule({
    match = {
        title = "match:class (hyprland-share-picker)",
    },
    center = true,
})
hl.window_rule({
    match = {
        class = "(hyprland-share-picker)",
    },
    size = "600 400",
})

-- float on and center on file pickers
hl.window_rule({
    match = {
        class = "xdg-desktop-portal-gtk",
        title = "^(Open.*Files?|Save.*Files?|All Files|Save)",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "xdg-desktop-portal-gtk",
        title = "^(Open.*Files?|Save.*Files?|All Files|Save)",
    },
    center = true,
})

-- XDG Desktop Portal
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- QT
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- GDK
hl.env("GDK_SCALE", "1")

-- Toolkit Backend
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Set the cursor size for xcursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Ozone
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- XWayland
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
