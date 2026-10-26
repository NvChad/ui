local api = vim.api
local state = require "nvchad.themes.state"
local redraw = require("volt").redraw
local utils = require "nvchad.themes.utils"

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

local function scroll(n, direction)
  if direction == "up" then
    vim.cmd("normal!" .. n .. "")
  else
    vim.cmd("normal!" .. n .. "")
  end
end

local M = {}

M.preview = require("nvchad.utils").debounce(30, function(theme)
  if state.confirmed or api.nvim_win_is_valid(state.win) then
    utils.reload_theme(theme)
  end
end)

M.move_down = function()
  if #state.themes_shown > 0 then
    local theme = set_index(1)
    M.preview(theme)
    redraw(state.buf, "all")

    if state.index + 1 > state.limit[state.style] then
      api.nvim_buf_call(state.buf, function()
        state.scrolled = true
        scroll(state.scroll_step[state.style], "down")
      end)
    end
  end
end

M.move_up = function()
  if #state.themes_shown > 0 then
    local theme = set_index(-1)
    M.preview(theme)
    redraw(state.buf, "all")

    api.nvim_buf_call(state.buf, function()
      state.scrolled = true
      scroll(state.scroll_step[state.style], "up")
    end)
  end
end

return M
