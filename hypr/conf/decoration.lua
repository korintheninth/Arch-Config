-- -----------------------------------------------------

-- General window decoration

-- -----------------------------------------------------
hl.config({
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 0.95,
        fullscreen_opacity = 1.0,
        rounding = 0,
        blur = {
            enabled = true,
            size = 2,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
        },
        shadow = {
            enabled = true,
            range = 5,
            render_power = 2,
        },
    },
})

hl.layer_rule({
    match = {
        namespace = "^waybar$",
    },
    blur = true,
})
