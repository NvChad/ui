local api = vim.api
local slider_id
local set_extmark = api.nvim_buf_set_extmark
local v = require "nvchad.shades.state"

local M = {}

M.draw = function(col)
  if col > v.w_with_pad then
    col = v.w_with_pad
  end

  local inactive = v.w_with_pad - col
  local virt_txt = { { string.rep("━", col), "NvimInternalError" }, { string.rep("━", inactive), "LineNr" } }

  local opts = { virt_text_pos = "overlay", virt_text = virt_txt, id = slider_id }
  slider_id = set_extmark(v.buf, v.ns, #v.palette_lines, v.xpad, opts)
end

M.toggle_shade_cols = function()
  v.blocklen = v.blocklen == 6 and 3 or 6
  v.palette_cols = v.palette_cols == 12 and 6 or 12
end

return M
