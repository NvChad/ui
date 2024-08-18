local M = {}
local api = vim.api
local utils = require "nvchad.color.utils"

local set_opt = api.nvim_set_option_value

local v = require "nvchad.huefy.state"
local mark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw
local layout = require "nvchad.huefy.layout"
local hex2rgb_ratio = require("base46.colors").hex2rgb_ratio

v.paletteNS = api.nvim_create_namespace "Huefy"
v.inputNS = api.nvim_create_namespace "HuefyInput"
v.toolsNS = api.nvim_create_namespace "HuefyTools"

dofile(vim.g.base46_cache .. "huefy")

M.open = function()
  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex
  v.sliders.r, v.sliders.g, v.sliders.b = hex2rgb_ratio(v.new_hex)

  v.palette_buf = api.nvim_create_buf(false, true)
  v.tools_buf = api.nvim_create_buf(false, true)

  mark_state[v.palette_buf] = { xpad = v.xpad, ns = v.paletteNS, buf = v.palette_buf }
  mark_state[v.tools_buf] = { xpad = v.xpad, ns = v.paletteNS, buf = v.tools_buf }

  require("nvchad.extmarks").gen_data(v.palette_buf, layout.palette)
  require("nvchad.extmarks").gen_data(v.tools_buf, layout.tools)

  local h = mark_state[v.palette_buf].h

  local win = api.nvim_open_win(v.palette_buf, true, {
    row = 1,
    col = 1,
    -- row = (vim.o.lines / 2) / 2,
    -- col = vim.o.columns / 5,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = " 󱥚 Huefy ",
    title_pos = "center",
  })

  local input_buf = api.nvim_create_buf(false, true)
  local tools_h = h - 4

  local input_win = api.nvim_open_win(input_buf, true, {
    row = -1,
    col = 3 + v.w,
    width = v.w,
    height = 1,
    relative = "win",
    win = win,
    style = "minimal",
    border = "single",
  })

  local tools_win = api.nvim_open_win(v.tools_buf, true, {
    row = 3,
    col = v.w + 3,
    width = v.tools_w,
    height = tools_h,
    relative = "win",
    win = win,
    style = "minimal",
    border = "single",
  })

  api.nvim_win_set_hl_ns(win, v.paletteNS)
  api.nvim_win_set_hl_ns(input_win, v.inputNS)
  api.nvim_win_set_hl_ns(tools_win, v.toolsNS)

  api.nvim_set_hl(v.paletteNS, "FloatBorder", { link = "HuefyBorder" })
  api.nvim_set_hl(v.paletteNS, "Normal", { link = "HuefyWin" })
  api.nvim_set_hl(v.inputNS, "FloatBorder", { link = "HuefyBorder2" })
  api.nvim_set_hl(v.inputNS, "Normal", { link = "HuefyWin2" })
  api.nvim_set_hl(v.toolsNS, "FloatBorder", { link = "HuefyBorder2" })
  api.nvim_set_hl(v.toolsNS, "Normal", { link = "HuefyWin2" })

  api.nvim_set_current_win(win)
  api.nvim_buf_set_lines(input_buf, 0, -1, false, { "   Enter color : #" .. v.hex })

  v.close = function()
    vim.cmd("bw" .. v.palette_buf)
    vim.cmd("bw" .. input_buf)
    vim.cmd("bw" .. v.tools_buf)
  end

  -- set empty lines to make all cols/rows available
  require("nvchad.extmarks").set_empty_lines(v.palette_buf, h, v.w)
  require("nvchad.extmarks").run(v.palette_buf)
  require("nvchad.extmarks").make_clickable(v.palette_buf)

  require("nvchad.extmarks").set_empty_lines(v.tools_buf, tools_h, v.w)
  require("nvchad.extmarks").run(v.tools_buf)
  require("nvchad.extmarks").make_clickable(v.tools_buf)

  -- enable insert mode in input win only!
  api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
    buffer = input_buf,
    callback = function(args)
      if args.event == "WinLeave" then
        vim.cmd "stopinsert"
        return
      end

      api.nvim_feedkeys("$a", "n", true)
    end,
  })

  ----------------- keymaps --------------------------
  vim.keymap.set("n", "q", v.close, { buffer = v.palette_buf })

  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.set_hex("#"..v.hex)
    redraw(v.palette_buf, "all")
    redraw(v.tools_buf, "all")
  end, { buffer = input_buf })

  set_opt("modifiable", false, { buf = v.palette_buf })
end

return M
