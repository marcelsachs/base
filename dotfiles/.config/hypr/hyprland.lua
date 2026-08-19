-- Dell SE2417HGX, physically left of the primary.
hl.monitor({
    output = "HDMI-A-2",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})

-- Acer XF240H, primary.
hl.monitor({
    output = "DP-2",
    mode = "1920x1080@144",
    position = "1920x0",
    scale = 1,
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

hl.config({
    input = {
        kb_layout = "de",
        kb_variant = "neo_qwertz",
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
    },
    animations = {
        enabled = false,
    },
    dwindle = {
        preserve_split = true,
    },
    cursor = {
        default_monitor = "DP-2",
    },
})

hl.device({
    name = "huion-huion-tablet_hs610-pen",
    output = "DP-2",
})

local mod = "SUPER"

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +10%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -10%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + D",      hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + M",      hl.dsp.exit())
hl.bind(mod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mod .. " + R",      hl.dsp.exec_cmd("hyprctl reload"))

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "d" }))

hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r", group_aware = true }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d", group_aware = true }))

hl.bind(mod .. " + G",           hl.dsp.group.toggle())
hl.bind(mod .. " + Tab",         hl.dsp.group.next())
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.group.prev())

for i = 1, 5 do
    hl.bind(mod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
