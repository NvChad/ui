local M = {}
local api = vim.api

M.config = {
  enabled = true,
  mode = "virtual", -- fg, bg, virtual
  virt_txt = "󱓻 ",

  highlight = {
    hex = true,
    lspvars = true,
  },
}

M.is_dark = function(hex)
  hex = hex:gsub("#", "")

  local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  local brightness = (r * 299 + g * 587 + b * 114) / 1000

  return brightness < 128
end

M.new_hlgroup = function(namespace, hex)
  local name = "hex_" .. hex:sub(2)

  local fg, bg = hex, hex

  if M.config.mode == "bg" then
    fg = M.is_dark(hex) and "white" or "black"
  else
    bg = "none"
  end

  api.nvim_set_hl(namespace, name, { fg = fg, bg = bg })
  return name
end

return M
