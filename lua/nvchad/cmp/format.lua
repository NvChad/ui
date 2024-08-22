local M = {}
local api = vim.api

M.tailwind = function(entry, item)
  local entryItem = entry:get_completion_item()
  local color = entryItem.documentation

  if color and type(color) == "string" then
    local hl = "cmp-square-" .. color:sub(2)

    if #api.nvim_get_hl(0, { name = hl }) == 0 then
      api.nvim_set_hl(0, hl, { fg = color })
    end

    item.kind = " 󱓻 "
    item.kind_hl_group = hl
    item.menu_hl_group = hl
  end
end

return M
