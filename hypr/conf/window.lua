-- -----------------------------------------------------

-- General window layout and colors

-- name: "Default"

-- -----------------------------------------------------
hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        col = {
            active_border = var_color5,
            inactive_border = var_color1,
        },
        layout = "scrolling",
        resize_on_border = true,
    },
})
