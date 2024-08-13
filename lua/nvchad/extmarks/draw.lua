local api = vim.api
local set_extmark = api.nvim_buf_set_extmark
local state = require "nvchad.extmarks.state"

local get_section = function(tb, name)
  for _, value in ipairs(tb) do
    if value.name == name then
      return value
    end
  end
end

return function(buf, name)
  local v = state[buf]
  local sec = get_section(v.layout, name)
  local section_lines = sec.lines()

  for line_i, val in ipairs(section_lines) do
    local row = line_i + sec.row
    local col = v.xpad

    v.clickables[row] = {}

    for _, mark in ipairs(val) do
      local strlen = vim.fn.strwidth(mark[1])
      col = col + strlen

      if mark[3] then
        local pos = { col_start = col - strlen, col_end = col, click = mark[3] }
        table.insert(v.clickables[row], pos)
      end
    end
  end

  -- remove 3rd item from virt_text table cuz its a function
  for _, line in ipairs(section_lines) do
    for _, marks in ipairs(line) do
      table.remove(marks, 3)
    end
  end

  for line, marks in ipairs(section_lines) do
    local row = line + sec.row
    local opts = { virt_text_pos = "overlay", virt_text = marks, id = v.ids[row] }
    local id = set_extmark(v.buf, v.ns, row - 1, v.xpad, opts)

    if not v.ids_set then
      table.insert(v.ids, id)
    end
  end
end
