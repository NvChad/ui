local M = {}
local api = vim.api
local v = require "nvchad.menu.state"
local layout = require "nvchad.menu.layout"
local mark_state = require "nvchad.extmarks.state"

M.open = function(items)
  v.ns = api.nvim_create_namespace "NvMenu"
  v.buf = api.nvim_create_buf(false, true)

  v.items = items
  local h = #items
  v.w = require("nvchad.menu.utils").get_width(items)

  v.w = v.w + v.item_gap

  local win = api.nvim_open_win(v.buf, false, {
    relative = "mouse",
    width = v.w,
    height = #items,
    row = 1,
    col = 0,
    border = "single",
    style = "minimal",
  })

  mark_state[v.buf] = {
    ns = v.ns,
    buf = v.buf,
  }

  require("nvchad.extmarks").gen_data(v.buf, layout)
  require("nvchad.extmarks").mappings { v.buf }

  api.nvim_win_set_hl_ns(win, v.ns)
  api.nvim_set_hl(v.ns, "Normal", { link = "ExBlack2Bg" })
  api.nvim_set_hl(v.ns, "FloatBorder", { link = "ExBlack2Border" })
  -- api.nvim_set_hl(v.ns, "FloatBorder", { link = "Comment" })

  require("nvchad.extmarks").run(v.buf, h, v.w)
  require "nvchad.extmarks.events" { bufs = { v.buf }, hover = true }
end

return M
