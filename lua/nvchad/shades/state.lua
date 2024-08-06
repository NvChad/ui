local M = {
  hex ="",
  ns = 0,
  blocklen = 6,
  xpad = 2,
  palette_cols = 6,
  step = 10,
  intensity = 5,
  palette_lines = {},
}

M.w = M.palette_cols * M.blocklen + (2 * M.xpad)
M.w_with_pad = M.w - (2 * M.xpad)

return M
