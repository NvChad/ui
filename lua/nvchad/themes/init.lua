local M = {}
local api = vim.api
local layout = require "nvchad.themes.layout"
local extmarks = require "volt"
local extmarks_events = require "volt.events"
local state = require "nvchad.themes.state"
local colors = dofile(vim.g.base46_cache .. "colors")

state.ns = api.nvim_create_namespace "NvThemes"

if not state.val then
  state.val = require("nvchad.utils").list_themes()
  state.themes_shown = state.val
end

local gen_word_pad = function()
  local largest = 0

  for i = state.index, state.index + state.limit, 1 do
    local namelen = #state.val[i]

    if namelen > largest then
      largest = namelen
    end
  end

  state.longest_name = largest
end

M.open = function()
  local oldwin = api.nvim_get_current_win()

  state.buf = api.nvim_create_buf(false, true)
  state.input_buf = api.nvim_create_buf(false, true)

  gen_word_pad()
  state.w = state.longest_name + state.word_gap + (#state.order * 2) + (state.xpad * 2)
  state.w = state.w + 4

  extmarks.gen_data {
    { buf = state.buf, layout = layout, xpad = state.xpad, ns = state.ns },
  }

  local h = state.limit + 1

  state.input_win = api.nvim_open_win(state.input_buf, true, {
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - state.w) / 2),
    width = state.w,
    height = 1,
    relative = "editor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
  })

  vim.cmd "startinsert"

  local win = api.nvim_open_win(state.buf, false, {
    row = 2,
    col = -1,
    width = state.w,
    height = h,
    relative = "win",
    style = "minimal",
    border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  })

  api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { "   " })

  vim.wo[state.input_win].winhl = "Normal:ExBlack2Bg,FloatBorder:ExBlack2Border"
  api.nvim_set_hl(state.ns, "Normal", { link = "ExDarkBg" })
  api.nvim_set_hl(state.ns, "FloatBorder", { link = "ExDarkBorder" })
  api.nvim_set_hl(state.ns, "NScrollbarOff", { fg = colors.one_bg2 })
  api.nvim_win_set_hl_ns(win, state.ns)

  api.nvim_set_current_win(state.input_win)

  extmarks.run(state.buf, { h = #state.val, w = state.w })
  extmarks_events.add(state.buf)

  ----------------- keymaps --------------------------
  extmarks.mappings {
    bufs = { state.buf, state.input_buf },
    input_buf = state.input_buf,
    close_func_post = function()
      api.nvim_set_current_win(oldwin)
    end,
  }

  require "nvchad.themes.mappings"
end

M.toggle = function()
  extmarks.toggle_func(M.open, state.visible)
  state.visible = not state.visible
end

return M
