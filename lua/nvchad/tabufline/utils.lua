local M = {}
local api = vim.api
local fn = vim.fn

local strep = string.rep
local cur_buf = api.nvim_get_current_buf

M.txt = function(str, hl)
  str = str or ""
  local a = "%#Tb" .. hl .. "#" .. str
  return a
end

M.btn = function(str, hl, func, arg)
  str = hl and M.txt(str, hl) or str
  arg = arg or ""
  return "%" .. arg .. "@Tb" .. func .. "@" .. str .. "%X"
end

local btn = M.btn
local txt = M.txt

M.buf_info = function(nr)
  local name = api.nvim_buf_get_name(nr)
  name = name:match "([^/\\]+)[/\\]*$"
  name = (name == "" or not name) and " No Name " or name
  return { nr = nr, name = name }
end

local function new_hl(group1, group2)
  local fg = fn.synIDattr(fn.synIDtrans(fn.hlID(group1)), "fg#")
  local bg = fn.synIDattr(fn.synIDtrans(fn.hlID("Tb" .. group2)), "bg#")
  api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. group1 .. group2 .. "#"
end

local function add_file_info(name, nr)
  local icon = "󰈚"
  local tbHlName = "BufO" .. (cur_buf() == nr and "n" or "ff")
  local icon_hl = new_hl("DevIconDefault", tbHlName)

  if name ~= " No Name " then
    local devicon, devicon_hl = require("nvim-web-devicons").get_icon(name)

    if devicon then
      icon = devicon
      icon_hl = new_hl(devicon_hl, tbHlName)
    end
  end

  -- padding around bufname; 15= maxnamelen + 2 icon & space + 2 close icon
  local pad = math.floor((23 - #name - 5) / 2)
  pad = pad == 0 and 1 or pad
  local maxname_len = 15

  name = string.sub(name, 1, 13) .. (#name > maxname_len and ".." or "")
  name = M.txt(" " .. name, tbHlName)

  return strep(" ", pad) .. (icon_hl .. icon .. name) .. strep(" ", pad - 1)
end

M.style_buf = function(buf)
  local close_btn = btn(" 󰅖 ", nil, "TbKillBuf", buf.nr)
  local name = btn(add_file_info(buf.name, buf.nr), nil, "GoToBuf", buf.nr)

  -- color close btn for focused / hidden  buffers
  if cur_buf() == buf.nr then
    close_btn = vim.bo[0].modified and txt("  ", "BufOnModified") or txt(close_btn, "BufOnClose")
    name = txt(name .. close_btn, "BufOn")
  else
    close_btn = vim.bo[buf.nr].modified and txt("  ", "BufOffModified") or txt(close_btn, "BufOffClose")
    name = txt(name .. close_btn, "BufOff")
  end

  return name
end

return M
