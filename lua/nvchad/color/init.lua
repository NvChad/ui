local M = {}
local api = vim.api
local lighten_hex = require("base46.colors").change_hex_lightness
local utils = require "nvchad.color.utils"

-- lightens hex color under cursor, negative arg will darken
M.lighten_on_cursor = function(n)
  local hex = utils.hex_on_cursor()

  if hex:match "^%x%x%x%x%x%x$" then
    local line = api.nvim_get_current_line()
    local new_hex = lighten_hex("#" .. hex, n)
    line = line:gsub(hex, new_hex:sub(2))
    api.nvim_set_current_line(line)
  end
end

return M
