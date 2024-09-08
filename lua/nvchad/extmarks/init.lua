local M = {}
local api = vim.api
local map = vim.keymap.set
local draw = require "nvchad.extmarks.draw"
local state = require "nvchad.extmarks.state"
local utils = require "nvchad.extmarks.utils"

local get_section = function(tb, name)
  for _, value in ipairs(tb) do
    if value.name == name then
      return value
    end
  end
end

M.gen_data = function(data)
  for _, info in ipairs(data) do
    state[info.buf] = {}

    local buf = info.buf
    local v = state[buf]

    v.clickables = {}
    v.hoverables = {}
    v.ids = {}
    v.xpad = info.xpad
    v.layout = info.layout
    v.ns = info.ns
    v.buf = buf

    local row = 0

    for _, value in ipairs(v.layout) do
      local lines = value.lines(buf)
      value.row = row
      row = row + #lines
    end

    v.h = row
  end
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

M.mappings = function(val)
  for _, buf in ipairs(val.bufs) do
    -- cycle bufs
    map("n", "<C-t>", function()
      utils.cycle_bufs(val.bufs)
    end, { buffer = buf })

    -- close
    map("n", "q", function()
      utils.close(val)
    end, { buffer = buf })
  end

  if val.input_buf then
    api.nvim_create_autocmd("WinEnter", {
      buffer = val.input_buf,
      command = "normal! $",
    })
  end
end

M.run = function(buf, opts)
  M.set_empty_lines(buf, opts.h, opts.w)
  require "nvchad.extmarks.highlights"

  M.redraw(buf, "all")
  state[buf].ids_set = true

  api.nvim_set_option_value("modifiable", false, { buf = buf })

  if not vim.g.extmarks_events then
    require("nvchad.extmarks.events").enable()
  end
end

M.toggle_func = function(open_func, ui_state)
  if ui_state then
    open_func()
  else
    api.nvim_feedkeys("q", "x", false)
  end
end

return M
