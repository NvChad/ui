local M = {}
local api = vim.api

M.hex_on_cursor = function()
  local hex = vim.fn.expand "<cword>"

  if hex:match "^%x%x%x%x%x%x$" then
    return hex
  end
end

return M
