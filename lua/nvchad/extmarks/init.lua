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

  if type(names) == "string" then
    draw(buf, get_section(v.layout, names))
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

M.close = function(val)
  vim.cmd("bw " .. table.concat(val, " "))
  vim.cmd "echo ''"

  if val.oldwin then
    api.nvim_set_current_win(val.oldwin)
  end
end

M.close_mapping = function(val)
  for _, buf in ipairs(val) do
    vim.keymap.set("n", "q", function()
      M.close(val)
    end, { buffer = buf })
  end

  return function()
    M.close(val)
  end
end

M.run = function(buf, h, w)
  M.set_empty_lines(buf, h, w)
  require "nvchad.extmarks.highlights"
  M.redraw(buf, "all")
  state[buf].ids_set = true
end

return M
