local M = {}

M.toggle = function()
  if vim.g.nvcheatsheet_displayed then
    vim.g.nvcheatsheet_displayed = false
    vim.cmd "bd"
  else
    vim.g.nvcheatsheet_displayed = true
    require("nvchad_ui.cheatsheet.draw").draw()
  end
end

M.init = function()
  local new_cmd = vim.api.nvim_create_user_command

  new_cmd("NvCheatsheet", function()
    require("nvchad_ui.cheatsheet.draw").draw()
  end, {})
end

return M
