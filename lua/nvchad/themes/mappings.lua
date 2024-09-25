local map = vim.keymap.set
local api = vim.api
local autocmd = api.nvim_create_autocmd
local state = require "nvchad.themes.state"
local redraw = require("volt").redraw

local function reload_theme(name)
  require("nvconfig").base46.theme = name
  require("base46").load_all_highlights()
  require("plenary.reload").reload_module "volt.highlights"
  require "volt.highlights"
end

local gg = function(n)
  local list = state.themes_shown

  if n == 1 and state.index < #list then
    state.index = state.index + n
  elseif n == -1 and state.index > 1 then
    state.index = state.index + n
  end

  state.active_theme = list[state.index]
  return state.active_theme
end

map("i", "<C-n>", function()
  if #state.themes_shown > 0 then
    local theme = gg(1)
    reload_theme(theme)
    redraw(state.buf, "all")
  end
end, { buffer = state.input_buf })

map("i", "<C-p>", function()
  if #state.themes_shown > 0 then
    local theme = gg(-1)
    reload_theme(theme)
    redraw(state.buf, "all")
  end
end, { buffer = state.input_buf })

map("i", "<cr>", function()
  local name = state.themes_shown[state.index]
  local chadrc = dofile(vim.fn.stdpath "config" .. "/lua/chadrc.lua")
  local old_theme = chadrc.ui.theme or chadrc.base46.theme

  old_theme = '"' .. old_theme .. '"'
  require("nvchad.utils").replace_word(old_theme, '"' .. name .. '"')

  vim.cmd.stopinsert()
  require("volt").close()
end, { buffer = state.input_buf })

map("i", "<BS>", function()
  local cursor = api.nvim_win_get_cursor(state.input_win)
  local col = cursor[2]

  if col > 6 then
    local termcode = api.nvim_replace_termcodes("<BS>", true, false, true)
    api.nvim_feedkeys(termcode, "n", false)
  end
end, { buffer = state.input_buf })

---------------------- autocmds ----------------------

api.nvim_win_set_cursor(state.input_win, { 1, 6 })

local function filter_themes(searchString)
  state.themes_shown = vim.tbl_filter(function(value)
    return string.find(value, searchString) ~= nil
  end, state.val)
end

autocmd("TextChangedI", {
  buffer = state.input_buf,

  callback = function()
    local input = api.nvim_get_current_line():sub(5, -1)
    input = input:gsub("%s", "")

    filter_themes(input)

    api.nvim_set_option_value("modifiable", true, { buf = state.buf })

    for i = 1, #state.val, 1 do
      local emptystr = string.rep(" ", state.w)
      api.nvim_buf_set_lines(state.buf, i - 1, i, false, { emptystr })
    end

    api.nvim_set_option_value("modifiable", false, { buf = state.buf })

    if #state.themes_shown > 0 then
      reload_theme(state.themes_shown[1])
    end

    redraw(state.buf, "all")
  end,
})
