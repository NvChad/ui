local M = {}
local api = vim.api

M.attach = require "nvchad.colorify.attach"

M.run = function()
  api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
    "VimResized",
    "LspAttach",
    "WinScrolled",
    "BufEnter",
  }, {
    -- callback = function(args)
    callback = function(args)
      M.attach(args.buf, args.event)
    end,
  })
end

return M
