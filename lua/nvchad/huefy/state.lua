local hex2rgb_ratio = require("base46.colors").hex2rgb_ratio

local M = {
  hex = "",
  xpad = 1,
  step = 10,
  intensity = 5,
  close = nil,

  sliders = {
    r = 0,
    b = 0,
    g = 0,
    saturation = 20,
    lightness = 20,
  },

  contrast_mode = "vibrant",
  lightness_mode = "light",
}

M.w = 36 + (2 * M.xpad)
M.w_with_pad = M.w - (2 * M.xpad)

M.tools_w = M.w
M.tools_with_pad = M.tools_w - (2 * M.xpad)

M.set_hex = function(val)
  M.new_hex = val:sub(2)
  M.sliders.r, M.sliders.g, M.sliders.b = hex2rgb_ratio(val)
end

return M
