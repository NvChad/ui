local new_cmd = vim.api.nvim_create_user_command
local config = require("core.utils").load_config().ui

vim.opt.statusline = "%!v:lua.require('nvchad_ui.statusline').run()"

-- lazyload tabufline
require "nvchad_ui.tabufline.lazyload"

-- Command to toggle NvDash
new_cmd("Nvdash", function()
  if vim.g.nvdash_displayed then
    vim.cmd "bd"
  else
    require("nvchad_ui.nvdash").open(vim.api.nvim_create_buf(false, true))
  end
end, {})

-- load nvdash
if config.nvdash.load_on_startup then
  vim.defer_fn(function()
    require("nvchad_ui.nvdash").open()
  end, 0)
end

vim.g.nvcheatsheet_displayed = false

-- command to toggle cheatsheet
new_cmd("NvCheatsheet", function()
  vim.g.nvcheatsheet_displayed = not vim.g.nvcheatsheet_displayed

  if vim.g.nvcheatsheet_displayed then
    require("nvchad_ui.cheatsheet").draw()
  else
    vim.cmd "bd"
  end
end, {})
