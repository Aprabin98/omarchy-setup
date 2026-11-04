-- Portable fallback: use each display's preferred mode and let Hyprland
-- arrange it. Machine-specific scaling belongs in hosts/<profile>/monitors.lua.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
