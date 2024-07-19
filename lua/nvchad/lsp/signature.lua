local M = {}
 
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded",
  focusable = false,
  silent = true
})
 
local result = false
local function check_triggeredChars(triggerChars)
  local cur_line = vim.api.nvim_get_current_line()
  local pos = vim.api.nvim_win_get_cursor(0)[2]
 
  cur_line = cur_line:gsub("%s+$", "") -- rm trailing spaces
 
  if cur_line:sub(pos, pos) == ' ' then
    return result
  end
 
  for _, char in ipairs(triggerChars) do
    if cur_line:sub(pos, pos) == char then
      result = true
      return result
    end
  end
 
  result = false
  return false
end
 
M.setup = function(client, bufnr)
  local group = vim.api.nvim_create_augroup("LspSignature", { clear = false })
  vim.api.nvim_clear_autocmds { group = group, buffer = bufnr }
 
  local triggerChars = client.server_capabilities.signatureHelpProvider.triggerCharacters
 
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    buffer = bufnr,
    callback = function()
      if check_triggeredChars(triggerChars) then
        vim.lsp.buf.signature_help()
      end
    end,
  })
end
 
return M
