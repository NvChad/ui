local M = {}

M.run = function()
  require "nvchad.colorify.run"
end

-- lightens hex color under cursor, negative arg will darken
M.lighten = require("nvchad.colorify.tools").lighten

return M
