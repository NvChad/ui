local M = {}
local config = require "nvchad_ui.config"

M.statusline = function()
  return require("nvchad_ui.statusline").run(config.statusline)
end

M.tabufline = function()
  return require("nvchad_ui.tabufline").run(config.tabufline)
end

M.setup = function()
  vim.opt.statusline = "%!v:lua.require('nvchad_ui').statusline()"

  -- lazyload tabufline
  require "nvchad_ui.tabufline.lazyload"(config.tabufline)

  -- dashboard
  if config.nvdash.load_on_startup then
    vim.defer_fn(function()
      require("nvchad_ui.nvdash").open()
    end, 0)
  end

  -- redraw dashboard on VimResized event
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if vim.bo.filetype == "NvDash" then
        vim.cmd "set modifiable"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
        require("nvchad_ui.nvdash").open()
      end
    end,
  })
end

return M
