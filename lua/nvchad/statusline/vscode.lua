local fn = vim.fn
local config = require("core.utils").load_config().ui.statusline

local function stbufnr()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
end

local function is_activewin()
  return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

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
  if not is_activewin() then
    return ""
  end

  local m = vim.api.nvim_get_mode().mode
  return "%#St_Mode#" .. string.format("  %s ", M.modes[m])
end

M.fileInfo = function()
  local icon = "󰈚 "
  local path = vim.api.nvim_buf_get_name(stbufnr())
  local name = (path == "" and "Empty ") or path:match "([^/\\]+)[/\\]*$"

  if name ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(name)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end

    name = " " .. name .. " "
  end

  return "%#StText# " .. icon .. name
end

M.git = function()
  if not vim.b[stbufnr()].gitsigns_head or vim.b[stbufnr()].gitsigns_git_status then
    return ""
  end

  return "  " .. vim.b[stbufnr()].gitsigns_status_dict.head .. "  "
end

M.gitchanges = function()
  if not vim.b[stbufnr()].gitsigns_head or vim.b[stbufnr()].gitsigns_git_status or vim.o.columns < 120 then
    return ""
  end

  local git_status = vim.b[stbufnr()].gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""

  return (added .. changed .. removed) ~= "" and (added .. changed .. removed .. " | ") or ""
end

-- LSP STUFF
M.LSP_progress = function()
  if not rawget(vim, "lsp") or vim.lsp.status or not is_activewin() then
    return ""
  end

  local Lsp = vim.lsp.util.get_progress_messages()[1]

  if vim.o.columns < 120 or not Lsp then
    return ""
  end

  if Lsp.done then
    vim.defer_fn(function()
      vim.cmd.redrawstatus()
    end, 1000)
  end

  local msg = Lsp.message or ""
  local percentage = Lsp.percentage or 0
  local title = Lsp.title or ""
  local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪢", "󰪣", "󰪤", "󰪥" }
  local ms = vim.loop.hrtime() / 1000000
  local frame = math.floor(ms / 120) % #spinners
  local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)

  if config.lsprogress_len then
    content = string.sub(content, 1, config.lsprogress_len)
  end

  return content or ""
end

M.LSP_Diagnostics = function()
  if not rawget(vim, "lsp") then
    return " 󰅚 0  0"
  end

  local errors = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.INFO })

  errors = (errors and errors > 0) and ("󰅚 " .. errors .. " ") or "󰅚 0 "
  warnings = (warnings and warnings > 0) and (" " .. warnings .. " ") or " 0 "
  hints = (hints and hints > 0) and ("󰛩 " .. hints .. " ") or ""
  info = (info and info > 0) and (" " .. info .. " ") or ""

  return vim.o.columns > 140 and errors .. warnings .. hints .. info or ""
end

M.filetype = function()
  local ft = vim.bo[stbufnr()].ft
  return ft == "" and "{} plain text  " or "{} " .. ft .. " "
end

M.LSP_status = function()
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_active_clients()) do
      if client.attached_buffers[stbufnr()] and client.name ~= "null-ls" then
        return (vim.o.columns > 100 and " 󰄭  " .. client.name .. "  ") or " 󰄭  LSP  "
      end
    end
  end

  return ""
end

M.cursor_position = function()
  return vim.o.columns > 140 and "%#StText# Ln %l, Col %c  " or ""
end

M.file_encoding = function()
  local encode = vim.bo[stbufnr()].fileencoding
  return string.upper(encode) == "" and "" or "%#St_encode#" .. string.upper(encode) .. "  "
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
