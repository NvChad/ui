local new_cmd = vim.api.nvim_create_user_command
local config = require("core.utils").load_config().ui

vim.opt.statusline = "%!v:lua.require('nvchad_ui.statusline." .. config.statusline.theme .. "').run()"

if config.tabufline.enabled then
  require "nvchad_ui.tabufline.lazyload"
end

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

-- command to toggle cheatsheet
new_cmd("NvCheatsheet", function()
  if vim.g.nvcheatsheet_displayed then
    vim.cmd "bd"
  else
    require("nvchad_ui.cheatsheet." .. config.cheatsheet.theme)()
  end
end, {})

-- redraw dashboard on VimResized event
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if vim.bo.filetype == "nvdash" then
      vim.opt_local.modifiable = true
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
      require("nvchad_ui.nvdash").open()
    elseif vim.bo.filetype == "nvcheatsheet" then
      vim.opt_local.modifiable = true
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
      require("nvchad_ui.cheatsheet." .. config.cheatsheet.theme)()
    end
  end,
})
