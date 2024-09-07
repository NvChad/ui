local M = {}
local api = vim.api
local utils = require "nvchad.color.utils"

local v = require "nvchad.shades.state"
local mark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw
local layout = require "nvchad.shades.layout"

v.ns = api.nvim_create_namespace "NvShades"

M.open = function()
  local oldwin = api.nvim_get_current_win()

  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex
  v.buf = api.nvim_create_buf(false, true)
  local input_buf = api.nvim_create_buf(false, true)

  mark_state[v.buf] = {
    xpad = v.xpad,
    ns = v.ns,
    buf = v.buf,
  }

  require("nvchad.extmarks").gen_data(v.buf, layout)

  require("nvchad.extmarks").mappings {
    bufs = { v.buf, input_buf },
    input_buf = input_buf,
    close_func_post = function()
      api.nvim_set_current_win(oldwin)
    end,
  }

  local h = mark_state[v.buf].h

  local win = api.nvim_open_win(v.buf, true, {
    row = 1,
    col = 0,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = " 󱥚 Color Shades ",
    title_pos = "center",
  })

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

  -- set empty lines to make all cols/rows available
  require("nvchad.extmarks").run(v.buf, h, v.w)
  require("nvchad.extmarks.events").add(v.buf)

  ----------------- keymaps --------------------------
  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.new_hex = v.hex
    redraw(v.buf, { "palettes", "footer" })
  end, { buffer = input_buf })
end

M.toggle = function()
  if v.visible then
    M.open()
  else
    v.close()
  end

  v.visible = not v.visible
end

return M
