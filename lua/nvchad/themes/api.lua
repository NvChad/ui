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

M.move_down = function()
  if #state.themes_shown > 0 then
    local theme = set_index(1)
    utils.reload_theme(theme)
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
    utils.reload_theme(theme)
    redraw(state.buf, "all")

    api.nvim_buf_call(state.buf, function()
      state.scrolled = true
      scroll(state.scroll_step[state.style], "up")
    end)
  end
end

return M
