local api = vim.api
local devicons_present, devicons = pcall(require, "nvim-web-devicons")
local fn = vim.fn
local tabufline_config = require("core.utils").load_config().ui.tabufline

dofile(vim.g.base46_cache .. "tbline")

local isBufValid = function(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end
---------------------------------------------------------- btn onclick functions ----------------------------------------------

vim.cmd "function! TbGoToBuf(bufnr,b,c,d) \n execute 'b'..a:bufnr \n endfunction"

vim.cmd [[
   function! TbKillBuf(bufnr,b,c,d) 
        call luaeval('require("nvchad_ui.tabufline").close_buffer(_A)', a:bufnr)
  endfunction]]

vim.cmd "function! TbNewTab(a,b,c,d) \n tabnew \n endfunction"
vim.cmd "function! TbGotoTab(tabnr,b,c,d) \n execute a:tabnr ..'tabnext' \n endfunction"
vim.cmd "function! TbTabClose(a,b,c,d) \n lua require('nvchad_ui.tabufline').closeAllBufs('closeTab') \n endfunction"
vim.cmd "function! TbCloseAllBufs(a,b,c,d) \n lua require('nvchad_ui.tabufline').closeAllBufs() \n endfunction"
vim.cmd "function! TbToggle_theme(a,b,c,d) \n lua require('base46').toggle_theme() \n endfunction"
vim.cmd "function! TbToggleTabs(a,b,c,d) \n let g:TbTabsToggled = !g:TbTabsToggled | redrawtabline \n endfunction"

-------------------------------------------------------- functions ------------------------------------------------------------
local function new_hl(group1, group2)
  local fg = fn.synIDattr(fn.synIDtrans(fn.hlID(group1)), "fg#")
  local bg = fn.synIDattr(fn.synIDtrans(fn.hlID(group2)), "bg#")
  api.nvim_set_hl(0, "Tbline" .. group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. "Tbline" .. group1 .. group2 .. "#"
end

local function getNvimTreeWidth()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == "NvimTree" then
      return api.nvim_win_get_width(win) + 1
    end
  end
  return 0
end

local function getBtnsWidth() -- close, theme toggle btn etc
  local width = 6
  if fn.tabpagenr "$" ~= 1 then
    width = width + ((3 * fn.tabpagenr "$") + 2) + 10
    width = not vim.g.TbTabsToggled and 8 or width
  end
  return width
end

local function add_fileInfo(name, bufnr)
  if devicons_present then
    local icon, icon_hl = devicons.get_icon(name, string.match(name, "%a+$"))

    if not icon then
      icon = "󰈚"
      icon_hl = "DevIconDefault"
    end

    icon = (
      api.nvim_get_current_buf() == bufnr and new_hl(icon_hl, "TbLineBufOn") .. " " .. icon
      or new_hl(icon_hl, "TbLineBufOff") .. " " .. icon
    )

    -- check for same buffer names under different dirs
    for _, value in ipairs(vim.t.bufs) do
      if isBufValid(value) then
        if name == fn.fnamemodify(api.nvim_buf_get_name(value), ":t") and value ~= bufnr then
          local other = {}
          for match in (vim.fs.normalize(api.nvim_buf_get_name(value)) .. "/"):gmatch("(.-)" .. "/") do
            table.insert(other, match)
          end

          local current = {}
          for match in (vim.fs.normalize(api.nvim_buf_get_name(bufnr)) .. "/"):gmatch("(.-)" .. "/") do
            table.insert(current, match)
          end

          name = current[#current]

          for i = #current - 1, 1, -1 do
            local value_current = current[i]
            local other_current = other[i]

            if value_current ~= other_current then
              if (#current - i) < 2 then
                name = value_current .. "/" .. name
              else
                name = value_current .. "/../" .. name
              end
              break
            end
          end
          break
        end
      end
    end

    -- padding around bufname; 24 = bufame length (icon + filename)
    local padding = (24 - #name - 5) / 2
    local maxname_len = 16

    name = (#name > maxname_len and string.sub(name, 1, 14) .. "..") or name
    name = (api.nvim_get_current_buf() == bufnr and "%#TbLineBufOn# " .. name) or ("%#TbLineBufOff# " .. name)

    return string.rep(" ", padding) .. icon .. name .. string.rep(" ", padding)
  end
end

local function styleBufferTab(nr)
  local close_btn = "%" .. nr .. "@TbKillBuf@ 󰅖 %X"
  local name = (#api.nvim_buf_get_name(nr) ~= 0) and fn.fnamemodify(api.nvim_buf_get_name(nr), ":t") or " No Name "
  name = "%" .. nr .. "@TbGoToBuf@" .. add_fileInfo(name, nr) .. "%X"

  -- add numbers to each tab in tabufline
  if tabufline_config.show_numbers then
    for index, value in ipairs(vim.t.bufs) do
      if nr == value then
        name = name .. index
        break
      end
    end
  end

  -- color close btn for focused / hidden  buffers
  if nr == api.nvim_get_current_buf() then
    close_btn = (vim.bo[0].modified and "%" .. nr .. "@TbKillBuf@%#TbLineBufOnModified#  ")
      or ("%#TbLineBufOnClose#" .. close_btn)
    name = "%#TbLineBufOn#" .. name .. close_btn
  else
    close_btn = (vim.bo[nr].modified and "%" .. nr .. "@TbKillBuf@%#TbBufLineBufOffModified#  ")
      or ("%#TbLineBufOffClose#" .. close_btn)
    name = "%#TbLineBufOff#" .. name .. close_btn
  end

  return name
end

---------------------------------------------------------- components ------------------------------------------------------------
local M = {}

M.CoverNvimTree = function()
  return "%#NvimTreeNormal#" .. (vim.g.nvimtree_side == "right" and "" or string.rep(" ", getNvimTreeWidth()))
end

M.bufferlist = function()
  local buffers = {} -- buffersults
  local available_space = vim.o.columns - getNvimTreeWidth() - getBtnsWidth()
  local current_buf = api.nvim_get_current_buf()
  local has_current = false -- have we seen current buffer yet?

  for _, bufnr in ipairs(vim.t.bufs) do
    if isBufValid(bufnr) then
      if ((#buffers + 1) * 21) > available_space then
        if has_current then
          break
        end

        table.remove(buffers, 1)
      end

      has_current = (bufnr == current_buf and true) or has_current
      table.insert(buffers, styleBufferTab(bufnr))
    end
  end

  vim.g.visibuffers = buffers
  return table.concat(buffers) .. "%#TblineFill#" .. "%=" -- buffers + empty space
end

vim.g.TbTabsToggled = 0

M.tablist = function()
  local result, number_of_tabs = "", fn.tabpagenr "$"

  if number_of_tabs > 1 then
    for i = 1, number_of_tabs, 1 do
      local tab_hl = ((i == fn.tabpagenr()) and "%#TbLineTabOn# ") or "%#TbLineTabOff# "
      result = result .. ("%" .. i .. "@TbGotoTab@" .. tab_hl .. i .. " ")
      result = (i == fn.tabpagenr() and result .. "%#TbLineTabCloseBtn#" .. "%@TbTabClose@󰅙 %X") or result
    end

    local new_tabtn = "%#TblineTabNewBtn#" .. "%@TbNewTab@  %X"
    local tabstoggleBtn = "%@TbToggleTabs@ %#TBTabTitle# TABS %X"

    return vim.g.TbTabsToggled == 1 and tabstoggleBtn:gsub("()", { [36] = " " })
      or new_tabtn .. tabstoggleBtn .. result
  end
end

M.buttons = function()
  local toggle_themeBtn = "%@TbToggle_theme@%#TbLineThemeToggleBtn#" .. vim.g.toggle_theme_icon .. "%X"
  local CloseAllBufsBtn = "%@TbCloseAllBufs@%#TbLineCloseAllBufsBtn#" .. " 󰅖 " .. "%X"
  return toggle_themeBtn .. CloseAllBufsBtn
end

M.run = function()
  local modules = require "nvchad_ui.tabufline.modules"

  -- merge user modules :D
  if tabufline_config.overriden_modules then
    modules = vim.tbl_deep_extend("force", modules, tabufline_config.overriden_modules())
  end

  local result = modules.bufferlist() .. (modules.tablist() or "") .. modules.buttons()
  return (vim.g.nvimtree_side == "left") and modules.CoverNvimTree() .. result or result .. modules.CoverNvimTree()
end

return M
