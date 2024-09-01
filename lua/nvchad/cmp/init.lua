local cmp_ui = require("nvconfig").ui.cmp
local cmp_style = cmp_ui.style
local format_kk = require "nvchad.cmp.format"

local atom_styled = cmp_style == "atom" or cmp_style == "atom_colored"
local fields = atom_styled and { "kind", "abbr", "menu" } or { "abbr", "kind", "menu" }

local M = {
  formatting = {
    format = function(entry, item)
      local icons = require "nvchad.icons.lspkind"

      item.menu = cmp_ui.lspkind_text and item.kind or ""
      item.menu_hl_group = atom_styled and "LineNr" or "CmpItemKind" .. (item.kind or "")

      item.kind = item.kind and icons[item.kind] or ""
      item.kind = " " .. item.kind .. " "

      if atom_styled then
        item.menu = " " .. item.menu
      end

      if cmp_ui.format_colors.tailwind then
        format_kk.tailwind(entry, item)
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
      winhighlight = cmp_style == "default" and "Normal:CmpPmenu,FLoatBorder:CmpBorder"
        or "Normal:CmpDoc,FloatBorder:CmpDocBorder",
    },
  },
}

return M
