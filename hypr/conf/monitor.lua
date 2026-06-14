-- -----------------------------------------------------

-- Monitor Setup

-- name: "Default"

-- -----------------------------------------------------
hl.monitor({
    output = "eDP-1",
    disabled = false,
    mode = "highrr",
    position = "auto-right",
    scale = 1,
})
hl.monitor({
    output = "HDMI-A-1",
    disabled = false,
    mode = "highres",
    position = "auto-left",
    scale = 1,
})
