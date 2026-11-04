-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Laptop panel: retain its existing 160% scale.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6 })

-- External HDMI screen: preferred resolution at 100% scale, arranged automatically.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
