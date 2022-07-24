local M = {}
local config = require "nvchad_ui.config"

-- lazyload tabufline
require "nvchad_ui.tabufline.lazyload"(config.tabufline)

M.statusline = function()
  return require("nvchad_ui.statusline").run(config.statusline)
end

M.tabufline = function()
  return require("nvchad_ui.tabufline").run(config.tabufline)
end

M.setup = function()
  vim.opt.statusline = "%!v:lua.require('nvchad_ui').statusline()"
  vim.opt.tabline = "%!v:lua.require('nvchad_ui').tabufline()"
end

return M
