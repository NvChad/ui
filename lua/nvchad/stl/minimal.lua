local config = require("nvconfig").ui.statusline
local sep_style = config.separator_style
local utils = require "nvchad.stl.utils"

sep_style = (sep_style ~= "round" and sep_style ~= "block") and "block" or sep_style

local default_sep_icons = {
  round = { left = "", right = "" },
  block = { left = "█", right = "█" },
}

local separators = (type(sep_style) == "table" and sep_style) or default_sep_icons[sep_style]

local sep_l = separators["left"]
local sep_r = "%#St_sep_r#" .. separators["right"] .. " %#ST_EmptySpace#"

local function gen_block(icon, txt, sep_l_hlgroup, iconHl_group, txt_hl_group)
  return sep_l_hlgroup .. sep_l .. iconHl_group .. icon .. " " .. txt_hl_group .. " " .. txt .. sep_r
end

local is_activewin = utils.is_activewin

local M = {}

M.mode = function()
  if not is_activewin() then
    return ""
  end

  local modes = utils.modes
  local m = vim.api.nvim_get_mode().mode

  return gen_block(
    "",
    modes[m][1],
    "%#St_" .. modes[m][2] .. "ModeSep#",
    "%#St_" .. modes[m][2] .. "Mode#",
    "%#St_" .. modes[m][2] .. "ModeText#"
  )
end

M.file = function()
  local x = utils.file()
  return gen_block(x[1], x[2], "%#St_file_sep#", "%#St_file_bg#", "%#St_file_txt#")
end

M.git = function()
  return "%#St_gitIcons#" .. utils.git()
end

M.lsp_msg = function()
  return "%#St_LspMsg#" .. utils.lsp_msg()
end

M.diagnostics = utils.diagnostics

M.lsp = function()
  return "%#St_Lsp#" .. utils.lsp()
end

M.cwd = function()
  local name = vim.loop.cwd():match ".+[\\/](.-)$"
  return gen_block("", name, "%#St_cwd_sep#", "%#St_cwd_bg#", "%#St_cwd_txt#")
end

M.cursor = function()
  return gen_block("", "%l/%c", "%#St_Pos_sep#", "%#St_Pos_bg#", "%#St_Pos_txt#")
end

M["%="] = "%="

return function()
  return utils.generate("default", M)
end
