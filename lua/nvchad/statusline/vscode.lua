local fn = vim.fn
local config = require("core.utils").load_config().ui.statusline
local utils = require "core.utils"

local M = {}

M.modes = {
  ["n"] = "NORMAL",
  ["no"] = "NORMAL (no)",
  ["nov"] = "NORMAL (nov)",
  ["noV"] = "NORMAL (noV)",
  ["noCTRL-V"] = "NORMAL",
  ["niI"] = "NORMAL i",
  ["niR"] = "NORMAL r",
  ["niV"] = "NORMAL v",
  ["nt"] = "NTERMINAL",
  ["ntT"] = "NTERMINAL (ntT)",

  ["v"] = "VISUAL",
  ["vs"] = "V-CHAR (Ctrl O)",
  ["V"] = "V-LINE",
  ["Vs"] = "V-LINE",
  [""] = "V-BLOCK",

  ["i"] = "INSERT",
  ["ic"] = "INSERT (completion)",
  ["ix"] = "INSERT completion",

  ["t"] = "TERMINAL",

  ["R"] = "REPLACE",
  ["Rc"] = "REPLACE (Rc)",
  ["Rx"] = "REPLACEa (Rx)",
  ["Rv"] = "V-REPLACE",
  ["Rvc"] = "V-REPLACE (Rvc)",
  ["Rvx"] = "V-REPLACE (Rvx)",

  ["s"] = "SELECT",
  ["S"] = "S-LINE",
  [""] = "S-BLOCK",
  ["c"] = "COMMAND",
  ["cv"] = "COMMAND",
  ["ce"] = "COMMAND",
  ["r"] = "PROMPT",
  ["rm"] = "MORE",
  ["r?"] = "CONFIRM",
  ["x"] = "CONFIRM",
  ["!"] = "SHELL",
}

M.mode = function()
  local m = vim.api.nvim_get_mode().mode
  return "%#St_Mode#" .. string.format("  %s ", M.modes[m])
end

M.fileInfo = function()
  local icon = " 󰈚 "
  local filename = (fn.expand "%" == "" and "Empty ") or fn.expand "%:t"

  if filename ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(filename)
      icon = (ft_icon ~= nil and " " .. ft_icon) or ""
    end

    filename = " " .. filename .. " "
  end

  return "%#StText# " .. icon .. filename
end

M.git = function()
  if not vim.b.gitsigns_head or vim.b.gitsigns_git_status then
    return ""
  end

  return "  " .. vim.b.gitsigns_status_dict.head .. "  "
end

M.gitchanges = function()
  if not vim.b.gitsigns_head or vim.b.gitsigns_git_status or vim.o.columns < 120 then
    return ""
  end

  local git_status = vim.b.gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""

  return (added .. changed .. removed) ~= "" and (added .. changed .. removed .. " | ") or ""
end

-- LSP STUFF
M.LSP_progress = function()
  local status = utils.get_message()

  if vim.o.columns < 120 or not status then
    return ""
  end

  if status.done then
    vim.defer_fn(function()
      vim.cmd.redrawstatus()
    end, 1000)
  end

  local msg = status.msg or ""
  local percentage = status.percentage or 100
  local title = status.title or ""
  local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪢", "󰪣", "󰪤", "󰪥" }
  -- Choose the frame based on the percentage
  local frame = percentage ~= 100 and math.floor(percentage * #spinners / 100) or 7
  local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)

  return (status.msg or status.title) and ("%#St_LspProgress#" .. content) or ""
end

M.LSP_Diagnostics = function()
  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

  errors = (errors and errors > 0) and ("󰅚 " .. errors .. " ") or "󰅚 0 "
  warnings = (warnings and warnings > 0) and (" " .. warnings .. " ") or " 0 "
  hints = (hints and hints > 0) and ("󰛩 " .. hints .. " ") or ""
  info = (info and info > 0) and (" " .. info .. " ") or ""

  return vim.o.columns > 140 and errors .. warnings .. hints .. info or ""
end

M.filetype = function()
  return vim.bo.ft == "" and "{} plain text  " or "{} " .. vim.bo.ft .. " "
end

M.LSP_status = function()
  local lsp_status = ""
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.attached_buffers[vim.api.nvim_get_current_buf()] then
      lsp_status = lsp_status .. client.name .. " "
    end
  end
  return #lsp_status > 0
      and ((vim.o.columns > 100 and "%#St_LspStatus# 󰄭  [" .. lsp_status:sub(0, #lsp_status - 1) .. "] ") or "%#St_LspStatus# 󰄭  LSP  ")
    or ""
end

M.cursor_position = function()
  return vim.o.columns > 140 and "%#StText# Ln %l, Col %c  " or ""
end

M.file_encoding = function()
  return string.upper(vim.bo.fileencoding) == "" and "" or "%#St_encode#" .. string.upper(vim.bo.fileencoding) .. "  "
end

M.cwd = function()
  local dir_name = "%#St_Mode# 󰉖 " .. fn.fnamemodify(fn.getcwd(), ":t") .. " "
  return (vim.o.columns > 85 and dir_name) or ""
end

M.run = function()
  local modules = {
    M.mode(),
    M.fileInfo(),
    M.git(),
    M.LSP_Diagnostics(),

    "%=",
    M.LSP_progress(),
    "%=",

    M.gitchanges(),
    M.cursor_position(),
    M.file_encoding(),
    M.filetype(),
    M.LSP_status(),
    M.cwd(),
  }

  if config.overriden_modules then
    config.overriden_modules(modules)
  end

  return table.concat(modules)
end

return M
