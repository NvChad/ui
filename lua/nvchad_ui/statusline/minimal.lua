local fn = vim.fn
local config = require("core.utils").load_config().ui.statusline
local sep_style = config.separator_style

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

local M = {}

M.modes = {
  ["n"] = { "NORMAL", "St_NormalMode" },
  ["no"] = { "NORMAL (no)", "St_NormalMode" },
  ["nov"] = { "NORMAL (nov)", "St_NormalMode" },
  ["noV"] = { "NORMAL (noV)", "St_NormalMode" },
  ["noCTRL-V"] = { "NORMAL", "St_NormalMode" },
  ["niI"] = { "NORMAL i", "St_NormalMode" },
  ["niR"] = { "NORMAL r", "St_NormalMode" },
  ["niV"] = { "NORMAL v", "St_NormalMode" },
  ["nt"] = { "NTERMINAL", "St_NTerminalMode" },
  ["ntT"] = { "NTERMINAL (ntT)", "St_NTerminalMode" },

  ["v"] = { "VISUAL", "St_VisualMode" },
  ["vs"] = { "V-CHAR (Ctrl O)", "St_VisualMode" },
  ["V"] = { "V-LINE", "St_VisualMode" },
  ["Vs"] = { "V-LINE", "St_VisualMode" },
  [""] = { "V-BLOCK", "St_VisualMode" },

  ["i"] = { "INSERT", "St_InsertMode" },
  ["ic"] = { "INSERT (completion)", "St_InsertMode" },
  ["ix"] = { "INSERT completion", "St_InsertMode" },

  ["t"] = { "TERMINAL", "St_TerminalMode" },

  ["R"] = { "REPLACE", "St_ReplaceMode" },
  ["Rc"] = { "REPLACE (Rc)", "St_ReplaceMode" },
  ["Rx"] = { "REPLACEa (Rx)", "St_ReplaceMode" },
  ["Rv"] = { "V-REPLACE", "St_ReplaceMode" },
  ["Rvc"] = { "V-REPLACE (Rvc)", "St_ReplaceMode" },
  ["Rvx"] = { "V-REPLACE (Rvx)", "St_ReplaceMode" },

  ["s"] = { "SELECT", "St_SelectMode" },
  ["S"] = { "S-LINE", "St_SelectMode" },
  [""] = { "S-BLOCK", "St_SelectMode" },
  ["c"] = { "COMMAND", "St_CommandMode" },
  ["cv"] = { "COMMAND", "St_CommandMode" },
  ["ce"] = { "COMMAND", "St_CommandMode" },
  ["r"] = { "PROMPT", "St_ConfirmMode" },
  ["rm"] = { "MORE", "St_ConfirmMode" },
  ["r?"] = { "CONFIRM", "St_ConfirmMode" },
  ["x"] = { "CONFIRM", "St_ConfirmMode" },
  ["!"] = { "SHELL", "St_TerminalMode" },
}

M.mode = function()
  local m = vim.api.nvim_get_mode().mode

  return gen_block(
    "",
    M.modes[m][1],
    "%#" .. M.modes[m][2] .. "Sep#",
    "%#" .. M.modes[m][2] .. "#",
    "%#" .. M.modes[m][2] .. "Text#"
  )
end

M.fileInfo = function()
  local icon = "󰈚"
  local filename = (fn.expand "%" == "" and "Empty") or fn.expand "%:t"

  if filename ~= "Empty" then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(filename)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
  end

  return gen_block(icon, filename, "%#St_file_sep#", "%#St_file_bg#", "%#St_file_txt#")
end

M.git = function()
  if not vim.b.gitsigns_head or vim.b.gitsigns_git_status then
    return ""
  end

  local git_status = vim.b.gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
  local branch_name = " " .. git_status.head

  return "%#St_gitIcons#" .. branch_name .. added .. changed .. removed
end

-- LSP STUFF
M.LSP_progress = function()
  if not rawget(vim, "lsp") then
    return ""
  end

  local Lsp = vim.lsp.util.get_progress_messages()[1]

  if vim.o.columns < 120 or not Lsp then
    return ""
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

  return ("%#St_LspProgress#" .. content) or ""
end

M.LSP_Diagnostics = function()
  if not rawget(vim, "lsp") then
    return ""
  end

  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

  errors = (errors and errors > 0) and ("%#St_lspError#" .. " " .. errors .. " ") or ""
  warnings = (warnings and warnings > 0) and ("%#St_lspWarning#" .. "  " .. warnings .. " ") or ""
  hints = (hints and hints > 0) and ("%#St_lspHints#" .. "󰛩 " .. hints .. " ") or ""
  info = (info and info > 0) and ("%#St_lspInfo#" .. "󰋼 " .. info .. " ") or ""

  return errors .. warnings .. hints .. info
end

M.LSP_status = function()
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_active_clients()) do
      if client.attached_buffers[vim.api.nvim_get_current_buf()] and client.name ~= "null-ls" then
        return (vim.o.columns > 100 and gen_block("", client.name, "%#St_lsp_sep#", "%#St_lsp_bg#", "%#St_lsp_txt#"))
          or "  LSP "
      end
    end
  end
end

M.cwd = function()
  return (
    vim.o.columns > 85
    and gen_block("", fn.fnamemodify(fn.getcwd(), ":t"), "%#St_cwd_sep#", "%#St_cwd_bg#", "%#St_cwd_txt#")
  ) or ""
end

M.cursor_position = function()
  return gen_block("", "%l/%c", "%#St_Pos_sep#", "%#St_Pos_bg#", "%#St_Pos_txt#")
end

M.file_encoding = function()
  return string.upper(vim.bo.fileencoding) == "" and "" or string.upper(vim.bo.fileencoding) .. "  "
end

M.run = function()
  local modules = require "nvchad_ui.statusline.minimal"

  if config.overriden_modules then
    modules = vim.tbl_deep_extend("force", modules, config.overriden_modules())
  end

  return table.concat {
    modules.mode(),
    modules.fileInfo(),
    modules.git(),

    "%=",
    modules.LSP_progress(),
    "%=",

    modules.file_encoding(),
    modules.LSP_Diagnostics(),
    modules.LSP_status() or "",
    modules.cwd(),
    modules.cursor_position(),
  }
end

return M
