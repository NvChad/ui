local fn = vim.fn
local utils = require "nvchad.stl.utils"

local M = {}

M.mode = function()
  if not utils.is_activewin() then
    return ""
  end

  local modes = utils.modes
  local m = vim.api.nvim_get_mode().mode

  return "%#St_Mode#  " .. modes[m][1] .. " "
end

M.file = function()
  local x = utils.file()
  local name = " " .. x[2] .. " "
  return "%#StText# " .. x[1] .. name
end

M.git = utils.git
M.lsp_msg = utils.lsp_msg
M.diagnostics = utils.diagnostics
M.lsp = utils.lsp
M.cursor = "%#StText# Ln %l, Col %c  "
M["%="] = "%="

M.cwd = function()
  local name = "%#St_Mode# 󰉖 " .. vim.loop.cwd():match ".+[\\/](.-)$" .. " "
  return (vim.o.columns > 85 and name) or ""
end

return function()
  return utils.generate("vscode", M)
end
