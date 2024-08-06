local api = vim.api
local v = require "nvchad.shades.state"
local set_extmark = api.nvim_buf_set_extmark
local lighten_hex = require("base46.colors").change_hex_lightness

local function color_infos()
  local light_blocks = {}
  local dark_blocks = {}

  for i = 1, v.palette_cols, 1 do
    local dark_hue = lighten_hex(v.hex, -1 * (i - 1) * v.intensity)
    local light_hue = lighten_hex(v.hex, (i - 1) * v.intensity)

    api.nvim_set_hl(v.ns, "hue" .. dark_hue:sub(2), { bg = dark_hue, fg = dark_hue })
    api.nvim_set_hl(v.ns, "hue" .. light_hue:sub(2), { bg = light_hue, fg = light_hue })

    table.insert(dark_blocks, { string.rep(" ", v.blocklen), "hue" .. dark_hue:sub(2) })
    table.insert(light_blocks, { string.rep(" ", v.blocklen), "hue" .. light_hue:sub(2) })
  end

  return { light_blocks, dark_blocks }
end

local function palette_lines()
  local palettes = color_infos()

  local lines = {
    {},
    { { "Lightened color by " .. v.intensity } },
    { { string.rep("-", v.w_with_pad), "Comment" } },

    palettes[1],
    palettes[1],

    {},
    { { "Darkened color by " .. v.intensity } },
    { { string.rep("-", v.w_with_pad), "Comment" } },

    palettes[2],
    palettes[2],

    {},
    {
      { "Intensity : " .. v.intensity .. ( v.intensity == 10 and "" or " ") },
      { "         " },
      { "  ", v.palette_cols == 12 and "@function" or "Comment" },
      { " ", v.palette_cols == 6 and "@function" or "Comment" },
      { " Columns" },
    },
  }

  return lines
end

local M = {}

local extmark_ids = {}

M.draw = function()
  v.palette_lines = palette_lines()
  v.color_blocks_rows = {4,5,9,10}

  for i, virt_txts in ipairs(v.palette_lines) do
    local opts = { virt_text_pos = "overlay", virt_text = virt_txts, id = extmark_ids[i] }
    local extmark_id = set_extmark(v.buf, v.ns, i - 1, 0 + v.xpad, opts)

    if #extmark_ids < #v.palette_lines then
      table.insert(extmark_ids, extmark_id)
    end
  end
end

return M
