-- -----------------------------------------------------

-- Keyboard Layout

-- -----------------------------------------------------

-- Keep this empty or generic so it doesn't override specific devices
hl.config({
    input = {
        kb_layout = "us",
        kb_options = "",
        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        touchpad = {
            natural_scroll = false,
            scroll_factor = 1.0,
        },
        sensitivity = 0,
    },
})

-- -----------------------------------------------------

-- Device Overrides

-- -----------------------------------------------------

-- Built-in laptop keyboard: Force Turkish
hl.device({
    name = "at-translated-set-2-keyboard",
    kb_layout = "tr",
})

-- All other keyboards will fall back to 'us' from the input block.

-- Since no 'kb_options' are set globally, they won't toggle.
