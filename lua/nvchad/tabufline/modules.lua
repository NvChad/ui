local api = vim.api
local fn = vim.fn
local g = vim.g

dofile(vim.g.base46_cache .. "tbline")

local txt = require("nvchad.tabufline.utils").txt
local btn = require("nvchad.tabufline.utils").btn
local strep = string.rep
local style_buf = require("nvchad.tabufline.utils").style_buf
local cur_buf = api.nvim_get_current_buf

---------------------------------------------------------- btn onclick functions ----------------------------------------------

vim.cmd "function! TbGoToBuf(bufnr,b,c,d) \n execute 'b'..a:bufnr \n endfunction"

vim.cmd [[
   function! TbKillBuf(bufnr,b,c,d) 
        call luaeval('require("nvchad.tabufline").close_buffer(_A)', a:bufnr)
  endfunction]]

vim.cmd "function! TbNewTab(a,b,c,d) \n tabnew \n endfunction"
vim.cmd "function! TbGotoTab(tabnr,b,c,d) \n execute a:tabnr ..'tabnext' \n endfunction"
vim.cmd "function! TbCloseAllBufs(a,b,c,d) \n lua require('nvchad.tabufline').closeAllBufs() \n endfunction"
vim.cmd "function! TbToggle_theme(a,b,c,d) \n lua require('base46').toggle_theme() \n endfunction"
vim.cmd "function! TbToggleTabs(a,b,c,d) \n let g:TbTabsToggled = !g:TbTabsToggled | redrawtabline \n endfunction"

-------------------------------------------------------- functions ------------------------------------------------------------

local function getNvimTreeWidth()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == "NvimTree" then
      return api.nvim_win_get_width(win) + 1
    end
  end
  return 0
end

------------------------------------- modules -----------------------------------------
local M = {}

M.NvimTreeOverlay = function()
  return "%#NvimTreeNormal#" .. strep(" ", getNvimTreeWidth())
end

M.bufferlist = function()
  local buffers = {}
  local available_space = vim.o.columns - getNvimTreeWidth()
  local has_current = false -- have we seen current buffer yet?

  for _, buf in ipairs(vim.t.bufs) do
    if ((#buffers + 1) * 24) > available_space then
      if has_current then
        break
      end

      table.remove(buffers, 1)
    end

    has_current = cur_buf() == buf.nr
    table.insert(buffers, buf.ui)
  end

  return table.concat(buffers) .. txt("%=", "Fill") -- buffers + empty space
end

g.TbTabsToggled = 0

M.tablist = function()
  local result, tabs = "", fn.tabpagenr "$"

  if tabs > 1 then
    for nr = 1, tabs, 1 do
      local tab_hl = "TabO" .. (nr == fn.tabpagenr() and "n" or "ff")
      result = result .. btn(" " .. nr .. " ", tab_hl, "GotoTab", nr)
    end

    local new_tabtn = btn("  ", "TabNewBtn", "NewTab")
    local tabstoggleBtn = btn(" 󰅂 ", "TabTitle", "ToggleTabs")
    local small_btn = btn(" 󰅁 ", "TabTitle", "ToggleTabs")

    return g.TbTabsToggled == 1 and small_btn or new_tabtn .. tabstoggleBtn .. result
  end

  return ""
end

M.buttons = function()
  local toggle_theme = btn(g.toggle_theme_icon, "ThemeToggleBtn", "Toggle_theme")
  local closeAllBufs = btn(" 󰅖 ", "CloseAllBufsBtn", "CloseAllBufs")
  return toggle_theme .. closeAllBufs
end

return function()
  local modules = {
    M.NvimTreeOverlay(),
    M.bufferlist(),
    M.tablist(),
    M.buttons(),
  }

  return table.concat(modules)
end
