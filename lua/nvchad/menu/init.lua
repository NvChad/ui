local M = {}
local api = vim.api
local state = require "nvchad.menu.state"
local layout = require "nvchad.menu.layout"
local ns = api.nvim_create_namespace "NvMenu"
local extmarks = require "nvchad.extmarks"
local extmarks_events = require "nvchad.extmarks.events"

M.open = function(items, opts)
  opts = opts or {}

  local buf = api.nvim_create_buf(false, true)
  state[buf] = { items = items, item_gap = opts.item_gap or 10 }

  local h = #items
  local bufv = state[buf]
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

  local win = api.nvim_open_win(buf, true, win_opts)

  extmarks.gen_data {
    { buf = buf, ns = ns, layout = layout },
  }

  api.nvim_win_set_hl_ns(win, ns)
  api.nvim_set_hl(ns, "Normal", { link = "ExBlack2Bg" })
  api.nvim_set_hl(ns, "FloatBorder", { link = "ExBlack2Border" })

  extmarks.run(buf, h, bufv.w)
  extmarks_events.add(buf)

  extmarks.mappings {
    bufs = vim.tbl_keys(state),
    close_func = function(bufid)
      state[bufid] = nil
    end,
  }
end

return M
