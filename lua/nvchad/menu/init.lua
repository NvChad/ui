local M = {}
local api = vim.api
local state = require "nvchad.menu.state"
local layout = require "nvchad.menu.layout"
local mark_state = require "nvchad.extmarks.state"
local ns = api.nvim_create_namespace "NvMenu"

M.open = function(items, opts)
  opts = opts or {}

  local buf = api.nvim_create_buf(false, true)

  state[buf] = { items = items, item_gap = opts.item_gap or 10 }
  local bufv = state[buf]

  local h = #items
  bufv.w = require("nvchad.menu.utils").get_width(items)
  bufv.w = bufv.w + bufv.item_gap

  vim.bo[buf].filetype = "NvMenu"

  local win_opts = {
    relative = "mouse",
    width = bufv.w,
    height = h,
    row = 1,
    col = 0,
    border = "single",
    style = "minimal",
  }

  if opts.nested then
    win_opts.relative = "win"

    local pos = vim.fn.getmousepos()
    win_opts.win = pos.winid
    win_opts.col = api.nvim_win_get_width(pos.winid) + 2
    win_opts.row = pos.winrow - 2
  end

  local win = api.nvim_open_win(buf, false, win_opts)

  mark_state[buf] = {
    ns = ns,
    buf = buf,
  }

  require("nvchad.extmarks").gen_data(buf, layout)

  require("nvchad.extmarks").mappings {
    bufs = vim.tbl_keys(state),
    close_func = function(bufid)
      state[bufid] = nil
    end,
  }

  api.nvim_win_set_hl_ns(win, ns)
  api.nvim_set_hl(ns, "Normal", { link = "ExBlack2Bg" })
  api.nvim_set_hl(ns, "FloatBorder", { link = "ExBlack2Border" })

  require("nvchad.extmarks").run(buf, h, bufv.w)
  require("nvchad.extmarks.events").add(buf)
end

return M
