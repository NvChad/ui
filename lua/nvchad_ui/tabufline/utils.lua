local M = {}
M.isBufValid = function(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end
return M
