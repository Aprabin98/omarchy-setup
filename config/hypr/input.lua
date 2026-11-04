
hl.gesture({fingers = 3, direction = "horizontal", action="workspace"})

-- Personal input overrides: natural scrolling and workspace swipe gestures.
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
      -- clickfinger_behavior = true,
      -- scroll_factor = 0.4,
    },
  },
})

-- Three-finger horizontal swipes switch workspaces with a faster transition.
-- hl.gesture({ fingers = 3, direction = "left", scale = 1.5, action = "workspace" })
-- hl.gesture({ fingers = 3, direction = "right", scale = 1.5, action = "workspace" })
