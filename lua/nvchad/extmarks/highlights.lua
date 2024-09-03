local colors = require("base46").get_theme_tb "base_30"
local lighten = require("base46.colors").change_hex_lightness

local hlgroups = {
  ExDarkBorder = { bg = colors.darker_black, fg = colors.darker_black },
  ExDarkBg = { bg = colors.darker_black },
  ExDarkNormal = { bg = colors.darker_black },

  ExGreyBorder = { bg = colors.one_bg3, fg = colors.one_bg3 },
  ExGreyBg = { bg = colors.one_bg3 },

  ExBlack2border = { bg = colors.black2, fg = colors.black2 },
  ExBlack2Bg = { bg = colors.black2 },

  ExBlack3Border = { bg = colors.one_bg2, fg = colors.one_bg2 },
  ExBlack3Bg = { bg = colors.one_bg2 },

  ExRed = { fg = colors.red },
  ExBlue = { fg = colors.blue },
  ExGreen = { fg = colors.green },

  ExInactive = { fg = lighten(colors.light_grey, 5) },

  ExHovered = { bg = colors.one_bg3 },
  -- ExHovered = { fg = colors.black, bg = colors.pmenu_bg },
  MenuLabel = { fg = lighten(colors.grey, 30) },
}

for name, val in pairs(hlgroups) do
  vim.api.nvim_set_hl(0, name, val)
end
