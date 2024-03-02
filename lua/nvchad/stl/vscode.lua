local fn = vim.fn
local is_activewin = require("nvchad.stl.utils").is_activewin

local M = {}

M.mode = function()
  if not is_activewin() then
    return ""
  end

  local modes = require("nvchad.stl.utils").modes
  local m = vim.api.nvim_get_mode().mode

  return "%#St_Mode#  " .. modes[m][1] .. " "
end

M.file = function()
  local x = require("nvchad.stl.utils").file()
  return "%#StText# " .. x[1] .. x[2]
end

M.git = require("nvchad.stl.utils").git
M.lsp_msg = require("nvchad.stl.utils").lsp_msg
M.diagnostics = require("nvchad.stl.utils").diagnostics
M.lsp = require("nvchad.stl.utils").lsp
M.cursor = "%#StText# Ln %l, Col %c  "
M["%="] = "%="

M.cwd = function()
  local dir_name = "%#St_Mode# 󰉖 " .. fn.fnamemodify(fn.getcwd(), ":t") .. " "
  return (vim.o.columns > 85 and dir_name) or ""
end

return function()
  return require("nvchad.stl.utils").generate("vscode", M)
end
