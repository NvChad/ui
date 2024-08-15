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

  {
    lines = ui.saturation_slider,
    name = "saturation_slider",
  },

  {
    lines = ui.lightness_slider,
    name = "lightness_slider",
  },
}

return M
