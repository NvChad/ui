local fn = vim.fn
local config = require("nvconfig").ui.statusline
local sep_style = config.separator_style

local default_sep_icons = {
  default = { left = "", right = "" },
  round = { left = "", right = "" },
  block = { left = "█", right = "█" },
  arrow = { left = "", right = "" },
}

local separators = (type(sep_style) == "table" and sep_style) or default_sep_icons[sep_style]

local sep_l = separators["left"]
local sep_r = separators["right"]

local is_activewin = require("nvchad.stl.utils").is_activewin

local M = {}

M.mode = function()
  if not is_activewin() then
    return ""
  end

  local modes = require("nvchad.stl.utils").modes

  local m = vim.api.nvim_get_mode().mode

  local current_mode = "%#St_" .. modes[m][2] .. "Mode#  " .. modes[m][1]
  local mode_sep1 = "%#St_" .. modes[m][2] .. "ModeSep#" .. sep_r
  return current_mode .. mode_sep1 .. "%#ST_EmptySpace#" .. sep_r
end

M.file = function()
  local x = require("nvchad.stl.utils").file()
  return "%#St_file_info# " .. x[1] .. x[2] .. "%#St_file_sep#" .. sep_r
end

M.git = function()
  return "%#St_gitIcons#" .. require("nvchad.stl.utils").git()
end

M.lsp_msg = function()
  return "%#St_LspProgress#" .. require("nvchad.stl.utils").lsp_msg()
end

M.diagnostics = require("nvchad.stl.utils").diagnostics

M.lsp = function()
  return "%#St_LspStatus#" .. require("nvchad.stl.utils").lsp()
end

M.cwd = function()
  local dir_icon = "%#St_cwd_icon#" .. "󰉋 "
  local dir_name = "%#St_cwd_text#" .. " " .. fn.fnamemodify(fn.getcwd(), ":t") .. " "
  return (vim.o.columns > 85 and ("%#St_cwd_sep#" .. sep_l .. dir_icon .. dir_name)) or ""
end

M.cursor = "%#St_pos_sep#" .. sep_l .. "%#St_pos_icon# %#St_pos_text# %p %% "
M["%="] = "%="

return function()
  return require("nvchad.stl.utils").generate("default", M)
end
