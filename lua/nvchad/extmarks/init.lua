local M = {}
local api = vim.api
local draw = require "nvchad.extmarks.draw"
local state = require "nvchad.extmarks.state"

local get_section = function(tb, name)
  for _, value in ipairs(tb) do
    if value.name == name then
      return value
    end
  end
end

M.gen_data = function(buf, layout)
  local v = state[buf]

  v.clickables = {}
  v.ids = {}
  v.layout = layout

  local row = 0

  for _, value in ipairs(v.layout) do
    local lines = value.lines()
    value.row = row
    row = row + #lines
  end

  v.h = row
end

M.redraw = function(buf, names)
  local v = state[buf]

  if names == "all" then
    for _, section in ipairs(v.layout) do
      draw(buf, section)
    end
    return
  end

  for _, name in ipairs(names) do
    draw(buf, get_section(v.layout, name))
  end
end

M.set_empty_lines = function(buf, n, w)
  local empty_lines = {}

  for _ = 1, n, 1 do
    table.insert(empty_lines, string.rep(" ", w))
  end

  api.nvim_buf_set_lines(buf, 0, -1, true, empty_lines)
end

M.run = function(buf, h, w)
  M.set_empty_lines(buf, h, w)
  M.redraw(buf, "all")
  state[buf].ids_set = true
end

return M
