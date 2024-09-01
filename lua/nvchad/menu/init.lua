local M = {}
local api = vim.api
local v = require "nvchad.menu.state"
local layout = require "nvchad.menu.layout"
local mark_state = require "nvchad.extmarks.state"
local set_opt = api.nvim_set_option_value

M.open = function(items)
  v.ns = api.nvim_create_namespace "NvMenu"
  local buf = api.nvim_create_buf(false, true)

  v.items = items
  local h = #items
  v.w = require("nvchad.menu.utils").get_width(items)

  v.w = v.w + v.item_gap

  local win = api.nvim_open_win(buf, false, {
    relative = "mouse",
    width = v.w,
    height = #items,
    row = 1,
    col = 0,
    border = "single",
    style = "minimal",
  })

  mark_state[buf] = {
    ns = v.ns,
    buf = buf,
  }

  require("nvchad.extmarks").gen_data(buf, layout)

  api.nvim_win_set_hl_ns(win, v.ns)
  api.nvim_set_hl(v.ns, "Normal", { link = "ExBlack2Bg" })
  api.nvim_set_hl(v.ns, "FloatBorder", { link = "ExBlack2Border" })
  -- api.nvim_set_hl(v.ns, "FloatBorder", { link = "Comment" })

  -- api.nvim_set_hl(v.ns, "Normal", { link = "ExDarkBg" })
  -- api.nvim_set_hl(v.ns, "FloatBorder", { link = "ExDarkBorder" })

  require("nvchad.extmarks").run(buf, h, v.w)
  require "nvchad.extmarks.events" { bufs = { buf }, hover = true }

  ----------------- keymaps --------------------------
  v.close = require("nvchad.extmarks").close_mapping { buf }
  vim.keymap.set("n", "<RightMouse>", v.close, { buffer = buf })

  api.nvim_create_autocmd({ "WinEnter" }, {
    group = vim.api.nvim_create_augroup("NvMenu", { clear = true }),
    callback = function(args)
      if args.buf ~= buf then
        v.close()
        vim.api.nvim_del_augroup_by_name "NvMenu"
      end
    end,
  })

  set_opt("modifiable", false, { buf = buf })
end

return M
