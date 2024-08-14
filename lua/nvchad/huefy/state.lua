local M = {
  hex = "",
  ns = 0,
  xpad = 1,
  step = 10,
  intensity = 5,
  blocklen = 6,
  palette_cols = 6,
  mode = "Variants",
  close = nil,
  rgb = {},
}

M.w = M.palette_cols * M.blocklen + (2 * M.xpad)
M.w_with_pad = M.w - (2 * M.xpad)

M.tools_w = M.w
M.tools_with_pad = M.tools_w - (2 * M.xpad)

return M
