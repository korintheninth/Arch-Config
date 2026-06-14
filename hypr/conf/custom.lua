-- SDL version
hl.env("SDL_VIDEODRIVER", "wayland")

-- env = SDL_VIDEODRIVER,x11
hl.config({
    misc = {
        enable_anr_dialog = false,
    },
})
