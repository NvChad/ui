local api = vim.api
local config = require "nvconfig"
local new_cmd = api.nvim_create_user_command

vim.o.statusline = "%!v:lua.require('nvchad.stl." .. config.ui.statusline.theme .. "')()"

if config.ui.tabufline.enabled then
  require "nvchad.tabufline.lazyload"
end

-- Command to toggle NvDash
new_cmd("Nvdash", function()
  if vim.g.nvdash_displayed then
    require("nvchad.tabufline").close_buffer()
  else
    require("nvchad.nvdash").open()
  end
end, {})

new_cmd("NvCheatsheet", function()
  if vim.g.nvcheatsheet_displayed then
    vim.cmd "bw"
  else
    require("nvchad.cheatsheet." .. config.cheatsheet.theme)()
  end
end, {})

vim.schedule(function()
  require "nvchad.au"
end)

new_cmd("K", function()
  require("plenary.reload").reload_module "nvchad.huefy"
  require("plenary.reload").reload_module "nvchad.extmarks"
  require("nvchad.huefy").open()
end, {})

