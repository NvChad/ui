local M = {}
local api = vim.api
local cmp_ui = require("nvconfig").ui.cmp
local colors_icon = cmp_ui.format_colors.icon .. " "

M.tailwind = function(entry, item)
  local entryItem = entry:get_completion_item()
  local color = entryItem.documentation

  if color and type(color) == "string" and color:match "^#%x%x%x%x%x%x$" then
    local hl = "hex-" .. color:sub(2)

    if #api.nvim_get_hl(0, { name = hl }) == 0 then
      api.nvim_set_hl(0, hl, { fg = color })
    end

    item.kind = cmp_ui.icons_left and colors_icon or " " .. colors_icon
    item.kind_hl_group = hl
    item.menu_hl_group = hl
  end
end

return M
