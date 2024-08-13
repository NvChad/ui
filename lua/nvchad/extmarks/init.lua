local M = {}
local api = vim.api
local draw = require "nvchad.extmarks.draw"
local state = require "nvchad.extmarks.state"

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

M.run = function(buf)
  local v = state[buf]

  for _, value in ipairs(v.layout) do
    draw(buf, value.name)
  end

  v.ids_set = true
end

M.redraw = function(buf, names)
  for _, name in ipairs(names) do
    draw(buf, name)
  end
end

M.set_empty_lines = function(buf, n, w)
  local empty_lines = {}

  for _ = 1, n, 1 do
    table.insert(empty_lines, string.rep(" ", w))
  end

  api.nvim_buf_set_lines(buf, 0, -1, true, empty_lines)
end

M.make_clickable = require("nvchad.extmarks.events")

return M
