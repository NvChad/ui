local M = {}

M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

M.is_activewin = function()
  return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

local orders = {
  default = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor" },
  vscode = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "cwd" },
}

M.generate = function(theme, modules)
  local config = require("nvconfig").ui.statusline
  local order = config.order or orders[theme]
  local result = {}

  if config.modules then
    for key, value in pairs(config.modules) do
      modules[key] = value
    end
  end

  for _, v in ipairs(order) do
    local module = modules[v]
    module = type(module) == "string" and module or module()
    table.insert(result, module)
  end

  return table.concat(result)
end

-- 2nd item is highlight groupname St_NormalMode
M.modes = {
  ["n"] = { "NORMAL", "Normal" },
  ["no"] = { "NORMAL (no)", "Normal" },
  ["nov"] = { "NORMAL (nov)", "Normal" },
  ["noV"] = { "NORMAL (noV)", "Normal" },
  ["noCTRL-V"] = { "NORMAL", "Normal" },
  ["niI"] = { "NORMAL i", "Normal" },
  ["niR"] = { "NORMAL r", "Normal" },
  ["niV"] = { "NORMAL v", "Normal" },
  ["nt"] = { "NTERMINAL", "NTerminal" },
  ["ntT"] = { "NTERMINAL (ntT)", "NTerminal" },

  ["v"] = { "VISUAL", "Visual" },
  ["vs"] = { "V-CHAR (Ctrl O)", "Visual" },
  ["V"] = { "V-LINE", "Visual" },
  ["Vs"] = { "V-LINE", "Visual" },
  [""] = { "V-BLOCK", "Visual" },

  ["i"] = { "INSERT", "Insert" },
  ["ic"] = { "INSERT (completion)", "Insert" },
  ["ix"] = { "INSERT completion", "Insert" },

  ["t"] = { "TERMINAL", "Terminal" },

  ["R"] = { "REPLACE", "Replace" },
  ["Rc"] = { "REPLACE (Rc)", "Replace" },
  ["Rx"] = { "REPLACEa (Rx)", "Replace" },
  ["Rv"] = { "V-REPLACE", "Replace" },
  ["Rvc"] = { "V-REPLACE (Rvc)", "Replace" },
  ["Rvx"] = { "V-REPLACE (Rvx)", "Replace" },

  ["s"] = { "SELECT", "Select" },
  ["S"] = { "S-LINE", "Select" },
  [""] = { "S-BLOCK", "Select" },
  ["c"] = { "COMMAND", "Command" },
  ["cv"] = { "COMMAND", "Command" },
  ["ce"] = { "COMMAND", "Command" },
  ["r"] = { "PROMPT", "Confirm" },
  ["rm"] = { "MORE", "Confirm" },
  ["r?"] = { "CONFIRM", "Confirm" },
  ["x"] = { "CONFIRM", "Confirm" },
  ["!"] = { "SHELL", "Terminal" },
}

-- credits to ii14 for str:match func
M.file = function()
  local icon = "󰈚"
  local path = vim.api.nvim_buf_get_name(M.stbufnr())
  local name = (path == "" and "Empty") or path:match "([^/\\]+)[/\\]*$"

  if name ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(name)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
  end
  if vim.o.columns < 50 then
    name = ""
  elseif vim.o.columns < 100 then
    local prefix = ""
    if name:match "^%." then
      prefix = "."
      name = name:sub(2) or ""
    end
    name = name:gsub("%.[^%.]*$", "") or ""
    if vim.o.columns < 75 and string.len(name) > 2 then
      name = name:sub(1, 1) .. "" .. name:sub(name:len())
    end
    name = prefix .. name
  end
  return { icon, name }
end

M.git = function()
  if not vim.b[M.stbufnr()].gitsigns_head or vim.b[M.stbufnr()].gitsigns_git_status then
    return ""
  end

  local git_status = vim.b[M.stbufnr()].gitsigns_status_dict
  local blank = " "
  if vim.o.columns < 120 then
    blank = ""
  end
  local added = (git_status.added and git_status.added ~= 0) and (" " .. blank .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and (" " .. blank .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and (" " .. blank .. git_status.removed) or ""
  local branch_name = "" .. blank .. git_status.head
  if vim.o.columns < 40 then
    return " "
  end
  if vim.o.columns < 80 then
    return "" .. added .. changed .. removed
  end
  return " " .. branch_name .. added .. changed .. removed
end

M.lsp_msg = function()
  if not rawget(vim, "lsp") or vim.lsp.status or not M.is_activewin() then
    return ""
  end

  local Lsp = vim.lsp.util.get_progress_messages()[1]

  if vim.o.columns < 50 or not Lsp then
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
  local pp = math.floor((percentage % 100) * 8 / 100)
  if vim.o.columns < 100 then
    local waiting = { " ", ".", ":", "" }
    local frame2 = math.floor(ms / 120) % #waiting
    local mini_title = ""
    for word in title:gmatch "([^%s]+)" do
      if mini_title:len() > 4 then
        break
      end
      mini_title = mini_title .. word:sub(0, 2)
    end
    content = string.format(" %%<%s%s%s ", spinners[pp + 1], mini_title, waiting[frame2 + 1])
  end
  if vim.o.columns < 50 then
    content = string.format(" %%<%s ", spinners[pp + 1])
  end
  return content or ""
end

M.lsp = function()
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_active_clients()) do
      if client.attached_buffers[M.stbufnr()] and client.name ~= "null-ls" then
        return (vim.o.columns > 100 and "   LSP ~ " .. client.name .. " ") or "  "
      end
    end
  end

  return ""
end

M.diagnostics = function()
  if not rawget(vim, "lsp") then
    return ""
  end

  local err = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.ERROR })
  local warn = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.INFO })
  local err_tag = ""
  local warn_tag = ""
  local hints_tag = "󰛩"
  local info_tag = "󰋼"

  if vim.o.columns > 90 then
    err_tag = err_tag .. " " .. err .. " "
    warn_tag = warn_tag .. " " .. warn .. " "
    hints_tag = hints_tag .. " " .. hints .. " "
    info_tag = info_tag .. " " .. info .. " "
  elseif vim.o.columns > 60 then
    err_tag = err_tag .. err .. " "
    warn_tag = warn_tag .. warn .. " "
    hints_tag = hints_tag .. hints .. " "
    info_tag = info_tag .. info .. " "
  elseif vim.o.columns > 40 then
    err_tag = err_tag .. err
    warn_tag = warn_tag .. warn
    hints_tag = hints_tag .. hints
    info_tag = info_tag .. info
  else
    err_tag = "" .. err
    warn_tag = "" .. warn
    hints_tag = "" .. hints
    info_tag = "" .. info
  end
  err = (err and err > 0) and ("%#St_lspError#" .. err_tag) or ""
  warn = (warn and warn > 0) and ("%#St_lspWarning#" .. warn_tag) or ""
  hints = (hints and hints > 0) and ("%#St_lspHints#" .. hints_tag) or ""
  info = (info and info > 0) and ("%#St_lspInfo#" .. info_tag) or ""

  return " " .. err .. warn .. hints .. info
end

return M
