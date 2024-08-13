local M = {}
local api = vim.api
local utils = require "nvchad.color.utils"

local set_opt = api.nvim_set_option_value

local v = require "nvchad.shades.state"
local mark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw
local layout = require "nvchad.shades.layout"

v.ns = api.nvim_create_namespace "NvShades"

M.open = function()
  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex

  v.buf = api.nvim_create_buf(false, true)

  mark_state[v.buf] = {
    xpad = v.xpad,
    ns = v.ns,
    buf = v.buf,
  }

  require("nvchad.extmarks").gen_data(v.buf, layout)

  local h = mark_state[v.buf].h

  local win = api.nvim_open_win(v.buf, true, {
    row = 1,
    col = 0,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = { { " 󱥚 Color Shades ", "floatTitle" } },
    title_pos = "center",
  })

  local input_buf = api.nvim_create_buf(false, true)

  api.nvim_open_win(input_buf, true, {
    row = h + 1,
    col = -1,
    width = v.w,
    height = 1,
    relative = "win",
    win = win,
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
  })

  api.nvim_buf_set_lines(input_buf, 0, -1, false, { "   Enter color : #" .. v.hex })

  api.nvim_win_set_hl_ns(win, v.ns)
  api.nvim_set_hl(v.ns, "FloatBorder", { link = "LineNr" })

  api.nvim_set_current_win(win)

  v.close = function()
    vim.cmd("bw" .. v.buf)
    vim.cmd("bw" .. input_buf)
  end

  -- set empty lines to make all cols/rows available
  require("nvchad.extmarks").set_empty_lines(v.buf, h, v.w)
  require("nvchad.extmarks").run(v.buf)
  require("nvchad.extmarks").make_clickable(v.buf)

  -- enable insert mode in input win only!
  api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
    buffer = input_buf,
    callback = function(args)
      if args.event == "WinLeave" then
        vim.cmd "stopinsert"
        return
      end

      api.nvim_feedkeys("$", "n", true)
      api.nvim_feedkeys("a", "n", true)
    end,
  })

  ----------------- keymaps --------------------------
  vim.keymap.set("n", "q", v.close, { buffer = v.buf })

  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.new_hex = v.hex
    redraw(v.buf, { "palettes", "footer" })
  end, { buffer = input_buf })

  set_opt("modifiable", false, { buf = v.buf })
end

return M
