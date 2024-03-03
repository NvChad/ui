local M = {}
local api = vim.api
local fn = vim.fn
local buf_opt = api.nvim_buf_get_option
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

local function new_hl(group1, group2)
  local fg = fn.synIDattr(fn.synIDtrans(fn.hlID(group1)), "fg#")
  local bg = fn.synIDattr(fn.synIDtrans(fn.hlID("Tb" .. group2)), "bg#")
  api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. group1 .. group2 .. "#"
end

M.style_buf = function(buf)
  local icon = "󰈚"
  local tbHlName = "BufO" .. (buf.cur and "n" or "ff")
  local icon_hl = new_hl("DevIconDefault", tbHlName)
  local name = buf.name

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

  name = strep(" ", pad) .. (icon_hl .. icon .. name) .. strep(" ", pad - 1)

  local close_btn = btn(" 󰅖 ", nil, "TbKillBuf", buf.nr)
  name = btn(name, nil, "GoToBuf", buf.nr)

  -- color close btn for focused / hidden  buffers
  if buf.cur then
    close_btn = buf.modified and txt("  ", "BufOnModified") or txt(close_btn, "BufOnClose")
    name = txt(name .. close_btn, "BufOn")
  else
    close_btn = buf.modified and txt("  ", "BufOffModified") or txt(close_btn, "BufOffClose")
    name = txt(name .. close_btn, "BufOff")
  end

  return name
end

M.buf_info = function(nr)
  local name = api.nvim_buf_get_name(nr)
  name = name:match "([^/\\]+)[/\\]*$"
  name = (name == "" or not name) and " No Name " or name

  local buf = {
    nr = nr,
    name = name,
    cur = cur_buf() == nr,
    modified = buf_opt(nr, "modified"),
  }

  buf.ui = M.style_buf(buf)

  return buf
end

return M
