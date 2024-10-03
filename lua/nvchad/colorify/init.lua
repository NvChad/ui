local M = {}
local api = vim.api

local state = require "nvchad.colorify.state"
state.ns = api.nvim_create_namespace "Colorify"
api.nvim_set_hl_ns(state.ns)

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
      local tblen = #state.events

      if state.events[tblen] == "BufEnter" and args.event == "WinScrolled" then
        return
      end

      table.insert(state.events, args.event)

      if vim.bo[args.buf].bl then
        M.attach(args.buf, args.event)
      end
    end,
  })
end

return M
