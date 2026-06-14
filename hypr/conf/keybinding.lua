local var_mainMod = "SUPER"
local var_HYPRSCRIPTS = "~/.config/hypr/scripts"

-- -----------------------------------------------------

-- Key bindings

-- name: "Default"

-- -----------------------------------------------------

-- SUPER KEY

-- Applications
hl.bind(var_mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(var_mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(var_mainMod .. " + E", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(var_mainMod .. " + CTRL + E", hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))
hl.bind(var_mainMod .. " + CTRL + C", hl.dsp.exec_cmd("gnome-calculator"))

-- Display
hl.bind(var_mainMod .. " + SHIFT + code:60", hl.dsp.exec_cmd('hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep \'float:\' | awk \'{print $2}\') + 0.5}")'))
hl.bind(var_mainMod .. " + SHIFT + code:59", hl.dsp.exec_cmd('hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep \'float:\' | awk \'{print $2}\') - 0.5}")'))
hl.bind(var_mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor 1"))

-- Windows
hl.bind(var_mainMod .. " + Q", hl.dsp.window.close())
hl.bind(var_mainMod .. " + CTRL + Q", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(var_mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"))
hl.bind(var_mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0, action = "toggle" }))
hl.bind(var_mainMod .. " + M", hl.dsp.window.fullscreen({ mode = 1, action = "toggle" }))
hl.bind(var_mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var_mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(var_mainMod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(var_mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(var_mainMod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true,
})
hl.bind(var_mainMod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true,
})
hl.bind(var_mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(var_mainMod .. " + ALT + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(var_mainMod .. " + ALT + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(var_mainMod .. " + ALT + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(var_mainMod .. " + ALT + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(var_mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(var_mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -f hex"))
hl.bind(var_mainMod .. " + ALT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(var_mainMod .. " + ALT + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(var_mainMod .. " + ALT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(var_mainMod .. " + ALT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), {
    repeating = true,
})
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top(), {
    repeating = true,
})

-- Actions
hl.bind(var_mainMod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(var_mainMod .. " + PRINT", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/screenshot.sh"))
hl.bind(var_mainMod .. " + ALT + F", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/screenshot.sh --instant"))
hl.bind(var_mainMod .. " + ALT + S", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/screenshot.sh --instant-area"))
hl.bind(var_mainMod .. " + Escape", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/powermenu.sh"))
hl.bind(var_mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper --random"))
hl.bind(var_mainMod .. " + CTRL + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(var_mainMod .. " + ALT + W", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/wallpaper-automation.sh"))
hl.bind(var_mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -replace -i"))
hl.bind(var_mainMod .. " + CTRL + K", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/keybindings.sh"))
hl.bind(var_mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/launchbar.sh"))
hl.bind(var_mainMod .. " + CTRL + B", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/togglebar.sh"))
hl.bind(var_mainMod .. " + V", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/cliphist.sh"))
hl.bind(var_mainMod .. " + CTRL + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/power.sh lock"))
hl.bind(var_mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/hyprshade.sh rofi"))
hl.bind(var_mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/filesearch.sh"))

-- Workspaces
hl.bind(var_mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(var_mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(var_mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(var_mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(var_mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(var_mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(var_mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(var_mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(var_mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(var_mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(var_mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(var_mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(var_mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(var_mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(var_mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(var_mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(var_mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(var_mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(var_mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(var_mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(var_mainMod .. " + CTRL + L", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(var_mainMod .. " + CTRL + H", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(var_mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(var_mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(var_mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))

-- Fn keys
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"))
hl.bind(var_mainMod .. " + R", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/increase_brightness.sh"))
hl.bind(var_mainMod .. " + W", hl.dsp.exec_cmd(var_HYPRSCRIPTS .. "/decrease_brightness.sh"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +2%"), {
    locked = true,
    repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -2%"), {
    locked = true,
    repeating = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("code:248", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s +10"))
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s 10-"))
