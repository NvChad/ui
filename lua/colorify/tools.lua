local M = {}
local api = vim.api
local lighten_hex = require("base46.colors").change_hex_lightness

-- only for hex colors!
M.lighten = function(n)
  local cursor = api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = cursor[1], cursor[2]

  vim.g.cursor_col = vim.g.cursor_col or cursor_col
  vim.g.cursor_row = vim.g.cursor_row or cursor_row

  -- reset globals on new cursor pos
  if vim.g.cursor_col ~= cursor_col or vim.g.cursor_row ~= cursor_row then
    vim.g.hex = nil
    vim.g.hex_n = nil
    vim.g.cursor_col = cursor_col
    vim.g.cursor_row = cursor_row
  end

  local line = api.nvim_get_current_line()

  for col, hex in line:gmatch "()(#%x%x%x%x%x%x)" do
    if cursor_col >= col and cursor_col <= col + 7 then
      vim.g.hex_n = (vim.g.hex_n or 0) + n
      vim.g.hex = vim.g.hex or hex

      -- reset step
      if (hex:lower() == "#ffffff" and n > 0) or (hex == "#000000" and n < 0) then
        vim.g.hex_n = nil
        return
      end

      local new_color = lighten_hex(vim.g.hex, vim.g.hex_n)
      new_color = vim.g.hex:match "%u" and new_color:upper() or new_color:lower() -- maintain the case

      local newline = line:sub(1, col - 1) .. new_color .. line:sub(col + 7)

      api.nvim_set_current_line(newline)
      return
    end
  end
end

return M
