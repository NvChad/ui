local api = vim.api
local v = require "nvchad.shades.state"
local set_extmark = api.nvim_buf_set_extmark

local color_funcs = {
  Variants = require("base46.colors").change_hex_lightness,
  Saturation = require("base46.colors").change_hex_saturation,
  Hues = require("base46.colors").change_hex_hue,
}

local function color_infos()
  local gen_color = color_funcs[v.mode]
  local light_blocks = {}
  local dark_blocks = {}

  for i = 1, v.palette_cols, 1 do
    local dark_hue = gen_color(v.hex, -1 * (i - 1) * v.intensity)
    local light_hue = gen_color(v.hex, (i - 1) * v.intensity)

    api.nvim_set_hl(v.ns, "hue" .. dark_hue:sub(2), { bg = dark_hue, fg = dark_hue })
    api.nvim_set_hl(v.ns, "hue" .. light_hue:sub(2), { bg = light_hue, fg = light_hue })

    table.insert(dark_blocks, 1, { string.rep(" ", v.blocklen), "hue" .. dark_hue:sub(2) })
    table.insert(light_blocks, { string.rep(" ", v.blocklen), "hue" .. light_hue:sub(2) })
  end

  return { light_blocks, dark_blocks }
end

--------------------------- header ----------------------------
local checkbox = function(mode)
  return {
    icon = v.mode == mode and "  " or "  ",
    hl = v.mode == mode and "String" or nil,
  }
end

local tabs = function()
  return {
    { checkbox("Variants").icon .. "Variants  ", checkbox("Variants").hl },
    { checkbox("Saturation").icon .. "Saturation  ", checkbox("Saturation").hl },
    { checkbox("Hues").icon .. "Hues", checkbox("Hues").hl },
  }
end

for _, value in ipairs(tabs()) do
  table.insert(v.tab_items_pos, { len = #value[1], name = value[1]:match "%S+%s*(%S+)%s*$" })
end

local function palette_lines()
  local palettes = color_infos()

  local lines = {
    {},
    tabs(),

    { { string.rep("-", v.w_with_pad), "Comment" } },

    palettes[1],
    palettes[1],
    palettes[2],
    palettes[2],

    {},
    {
      { "Intensity : " .. v.intensity .. (v.intensity == 10 and "" or " ") },
      { "         " },
      { "  ", v.palette_cols == 12 and "Function" or "Comment" },
      { " ", v.palette_cols == 6 and "Function" or "Comment" },
      { " Columns" },
    },
  }

  return lines
end

local M = {}

local extmark_ids = {}

M.draw = function()
  v.palette_lines = palette_lines()

  for i, virt_txts in ipairs(v.palette_lines) do
    local opts = { virt_text_pos = "overlay", virt_text = virt_txts, id = extmark_ids[i] }
    local extmark_id = set_extmark(v.buf, v.ns, i - 1, 0 + v.xpad, opts)

    if #extmark_ids < #v.palette_lines then
      table.insert(extmark_ids, extmark_id)
    end
  end
end

M.tab_redraw = function(col)
  local accu_w = 0

  for _, item in ipairs(v.tab_items_pos) do
    accu_w = accu_w + item.len

    if col + 2 < accu_w then
      v.mode = item.name
      M.draw()
      return
    end
  end
end

return M
