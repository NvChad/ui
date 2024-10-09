local M = {
  scrolled = false,
  textchanged = false,
  prompt = "   ",
  index = 1,

  limit = {
    compact = 15,
    flat = 6,
    bordered = 7,
  },

  start_row = 1,
  xpad = 1,
  word_gap = 5,

  order = {
    "base01",
    "base02",
    "base03",
    "base04",
    "base08",
    "base09",
    "base0A",
    "base0B",
    "base0C",
    "base0D",
  },

  themes_shown = {},
  active_theme = "",

  icons = {
    compact = "󱓻 ",
    flat = " ",
    bordered = "󱓻 ",
    user = nil,
  },

  scroll_step = {
    compact = 1,
    flat = 3,
    bordered = 2,
  },
}

return M
