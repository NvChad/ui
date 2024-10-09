local api = vim.api
local autocmd = api.nvim_create_autocmd
local state = require "nvchad.themes.state"
local redraw = require("volt").redraw
local utils = require "nvchad.themes.utils"
local nvapi = require "nvchad.themes.api"

local map = function(mode, keys, func, opts)
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, func, opts)
  end
end

map("i", { "<C-n>", "<Down>" }, nvapi.move_down, { buffer = state.input_buf })
map("n", { "j", "<Down>" }, nvapi.move_down, { buffer = state.input_buf })
map("i", { "<C-p>", "<Up>" }, nvapi.move_up, { buffer = state.input_buf })
map("n", { "k", "<Up>" }, nvapi.move_up, { buffer = state.input_buf })

map({ "i", "n" }, { "<cr>" }, function()
  state.confirmed = true
  local name = state.themes_shown[state.index]
  package.loaded.chadrc = nil
  local old_theme = require("chadrc").base46.theme

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
    if state.scrolled then
      api.nvim_buf_call(state.buf, function()
        vim.cmd "normal! gg"
      end)
    end

    local promptlen = api.nvim_strwidth(state.prompt)
    local input = api.nvim_get_current_line():sub(promptlen + 1, -1)
    input = input:gsub("%s", "")

    state.index = 1

    state.themes_shown = utils.filter(state.val, input)

    api.nvim_set_option_value("modifiable", true, { buf = state.buf })

    for i = 1, #state.val, 1 do
      local emptystr = string.rep(" ", state.w)
      api.nvim_buf_set_lines(state.buf, i - 1, i, false, { emptystr })
    end

    api.nvim_set_option_value("modifiable", false, { buf = state.buf })

    if state.textchanged and #state.themes_shown > 0 then
      utils.reload_theme(state.themes_shown[1])
    end

    redraw(state.buf, "all")
    state.scrolled = false
    state.textchanged = true
  end,
})
