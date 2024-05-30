local M = {}
local api = vim.api
local lighten_hex = require("base46.colors").change_hex_lightness

-- only for hex colors!
M.lighten = function(n)
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local line = api.nvim_get_current_line()

  for col, hex in line:gmatch "()(#%x%x%x%x%x%x)" do
    if cursor_col >= col and cursor_col <= col + 7 then
      local newline = line:sub(1, col - 1) .. lighten_hex(hex, n) .. line:sub(col + 7)
      api.nvim_set_current_line(newline)

      return
    end
  end
end

return M
