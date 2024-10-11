local cmp_ui = require("nvconfig").ui.cmp
local cmp_style = cmp_ui.style
local format_kk = require "nvchad.cmp.format"

local atom_styled = cmp_style == "atom" or cmp_style == "atom_colored"
local fields = (atom_styled or cmp_ui.icons_left) and { "kind", "abbr", "menu" } or { "abbr", "kind", "menu" }

local abbr_opts = cmp_ui.format_abbr or {}
if not abbr_opts.maxwidth then
    abbr_opts.maxwidth = math.floor(vim.o.columns / 2)
    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("NvCmpAbbrMaxwidth", { clear = true }),
        pattern = "*",
        callback = function()
            abbr_opts.maxwidth = math.floor(vim.o.columns / 2)
        end
    })
end

local M = {
  formatting = {
    format = function(entry, item)
      local icons = require "nvchad.icons.lspkind"

      item.menu = cmp_ui.lspkind_text and item.kind or ""
      item.menu_hl_group = atom_styled and "LineNr" or "CmpItemKind" .. (item.kind or "")

      item.kind = item.kind and icons[item.kind] .. " " or ""
      item.kind = cmp_ui.icons_left and item.kind or " " .. item.kind

      if atom_styled or cmp_ui.icons_left then
        item.menu = " " .. item.menu
      end

      if cmp_ui.format_colors.tailwind then
        format_kk.tailwind(entry, item)
      end

      -- item.abbr maxwidth and minwidth
      local ellipsis_char = '…'
      local abbr_maxwidth = abbr_opts.maxwidth
      local abbr_minwidth = abbr_opts.minwidth or 0

      local abbr = item.abbr
      local truncated_abbr = vim.fn.strcharpart(abbr, 0, abbr_maxwidth)
      if truncated_abbr ~= abbr then
        item.abbr = truncated_abbr .. ellipsis_char
      elseif string.len(abbr) < abbr_minwidth then
        local padding = string.rep(' ', abbr_minwidth - string.len(abbr))
        item.abbr = abbr .. padding
      end

      return item
    end,

    fields = fields,
  },

  window = {
    completion = {
      scrollbar = false,
      side_padding = atom_styled and 0 or 1,
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None,FloatBorder:CmpBorder",
      border = atom_styled and "none" or "single",
    },

    documentation = {
      border = "single",
      winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
    },
  },
}

return M
