local M = {}
local state = require "nvchad.menu.state"
local strw = vim.fn.strwidth

local format_title = function(name, rtxt, hl, actions)
  local line = {}

  if name == " separator" then
    table.insert(line, { " " .. string.rep("─", state.w - 2), "LineNr" })
    return line
  end

  table.insert(line, { name, hl or "MenuLabel", actions })

  local gap = state.w - (strw(name) + strw(rtxt))
  table.insert(line, { string.rep(" ", gap), hl, actions })

  if rtxt then
    table.insert(line, { rtxt, hl or "LineNr", actions })
  end

  return line
end

M.items = function()
  local lines = {}

  for i, item in ipairs(state.items) do
    local hover_id = i .. "menu"
    local hovered = vim.g.nvmark_hovered == hover_id
    local hl = hovered and "ExHovered" or nil

    local actions = {
      hover = { id = hover_id, redraw = "items" },
      click = function()
        state.close()
        item.cmd()
        vim.api.nvim_del_augroup_by_name "NvMenu"
      end,
    }

    local mark = format_title(" " .. item.name, (item.rtxt or "") .. " ", hl, actions)
    table.insert(lines, mark)
  end

  return lines
end

return M
