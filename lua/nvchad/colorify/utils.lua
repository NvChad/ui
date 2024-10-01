local M = {}
local api = vim.api
local get_extmarks = api.nvim_buf_get_extmarks
local conf = require('nvconfig').colorify

function M.is_dark(hex)
  hex = hex:gsub("#", "")

  local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  local brightness = (r * 299 + g * 587 + b * 114) / 1000

  return brightness < 128
end

function M.add_hl(ns, hex)
  local name = "hex_" .. hex:sub(2)

  local fg, bg = hex, hex

  if conf.mode == "bg" then
    fg = M.is_dark(hex) and "white" or "black"
  else
    bg = "none"
  end

  api.nvim_set_hl(ns, name, { fg = fg, bg = bg })
  return name
end

function M.not_colored(buf, ns, linenr, col, hl_group, opts)
  local ms = get_extmarks(buf, ns, { linenr, col }, { linenr, opts.end_col }, { details = true })
  ms = #ms == 0 and {} or ms[1]

  local old_hl

  if #ms > 0 then
    opts.id = ms[1]
    old_hl = ms[4].hl_group or ms[4].virt_text[1][2]
  end

  return #ms == 0 or old_hl ~= hl_group
end

return M
