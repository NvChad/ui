local ui = require "nvchad.huefy.ui"

local M = {}

M.palette = {
  {
    lines = ui.palettes,
    name = "palettes",
  },

  {
    lines = ui.hue,
    name = "hue",
  },

  {
    lines = ui.footer,
    name = "footer",
  },
}

M.tools = {
  {
    lines = ui.rgb_slider,
    name = "rgb_slider",
  },
}

return M
