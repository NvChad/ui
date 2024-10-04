local api = vim.api
local autocmd = api.nvim_create_autocmd
local state = require "nvchad.themes.state"
local redraw = require("volt").redraw

local scrolled = false
local textchanged = false

local function reload_theme(name)
  require("nvconfig").base46.theme = name
  require("base46").load_all_highlights()
  require("plenary.reload").reload_module "volt.highlights"
  require "volt.highlights"
end

local map = function(mode, keys, func, opts)
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, func, opts)
  end
end

local set_index = function(n)
  local list = state.themes_shown

  if n == 1 and state.index < #list then
    state.index = state.index + n
  elseif n == -1 and state.index > 1 then
    state.index = state.index + n
  end

  state.active_theme = list[state.index]
  return state.active_theme
end

local function scroll_down(n, direction)
  if direction == "up" then
    vim.cmd("normal!" .. n .. "")
  else
    vim.cmd("normal!" .. n .. "")
  end
end

local function move_down()
  if #state.themes_shown > 0 then
    local theme = set_index(1)
    reload_theme(theme)
    redraw(state.buf, "all")

    if state.index + 1 > state.limit[state.style] then
      api.nvim_buf_call(state.buf, function()
        scrolled = true
        scroll_down(state.scroll_step[state.style], "down")
      end)
    end
  end
end

map("i", { "<C-n>", "<Down>" }, move_down, { buffer = state.input_buf })
map("n", { "j", "<Down>" }, move_down, { buffer = state.input_buf })

local function move_up()
  if #state.themes_shown > 0 then
    local theme = set_index(-1)
    reload_theme(theme)
    redraw(state.buf, "all")

    api.nvim_buf_call(state.buf, function()
      scrolled = true
      scroll_down(state.scroll_step[state.style], "up")
    end)
  end
end

map("i", { "<C-p>", "<Up>" }, move_up, { buffer = state.input_buf })
map("n", { "k", "<Up>" }, move_up, { buffer = state.input_buf })

map({ "i", "n" }, { "<cr>" }, function()
  local name = state.themes_shown[state.index]
  package.loaded.chadrc = nil
  local chadrc = require "chadrc"
  local old_theme = chadrc.base46.theme

  old_theme = '"' .. old_theme .. '"'
  require("nvchad.utils").replace_word(old_theme, '"' .. name .. '"')

  require("volt").close()
end, { buffer = state.input_buf })

-- delete text
map("i", { "<C-w>" }, function()
  vim.api.nvim_input "<c-s-w>"
end, { buffer = state.input_buf })

---------------------- autocmds ----------------------

api.nvim_win_set_cursor(state.input_win, { 1, 6 })

autocmd("TextChangedI", {
  buffer = state.input_buf,

  callback = function()
    if scrolled then
      api.nvim_buf_call(state.buf, function()
        vim.cmd "normal! gg"
      end)
    end

    local promptlen = api.nvim_strwidth(state.prompt)
    local input = api.nvim_get_current_line():sub(promptlen + 1, -1)
    input = input:gsub("%s", "")

    state.index = 1

    state.themes_shown = require("nvchad.themes.utils").filter(state.val, input)

    api.nvim_set_option_value("modifiable", true, { buf = state.buf })

    for i = 1, #state.val, 1 do
      local emptystr = string.rep(" ", state.w)
      api.nvim_buf_set_lines(state.buf, i - 1, i, false, { emptystr })
    end

    api.nvim_set_option_value("modifiable", false, { buf = state.buf })

    if textchanged and #state.themes_shown > 0 then
      reload_theme(state.themes_shown[1])
    end

    redraw(state.buf, "all")
    scrolled = false
    textchanged = true
  end,
})
