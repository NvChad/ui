local api = vim.api
local v = require "nvchad.shades.state"
local redraw = require("nvchad.extmarks").redraw

local M = {}

M.tabs = function()
  local modes = { "Variants", "Saturation", "Hues" }
  local result = {}

  for _, name in ipairs(modes) do
    local mark = {
      (v.mode == name and "  " or "  ") .. name,
      v.mode == name and "String" or nil,
      function()
        v.mode = name
        redraw(v.buf, { "tabs", "palettes" })
      end,
    }

    table.insert(result, mark)
    table.insert(result, { "  " })
  end

  return {
    {},
    result,
    { { string.rep("-", v.w_with_pad), "LineNr" } },
  }
end

------------------------------- color blocks ----------------------------------------
local color_funcs = {
  Variants = require("base46.colors").change_hex_lightness,
  Saturation = require("base46.colors").change_hex_saturation,
  Hues = require("base46.colors").change_hex_hue,
}

M.palettes = function()
  local gen_color = color_funcs[v.mode]
  local blockstr = string.rep(" ", v.blocklen)

  local light_blocks = {}
  local dark_blocks = {}

  for i = 1, v.palette_cols, 1 do
    local dark = gen_color(v.hex, -1 * (i - 1) * v.intensity)
    local light = gen_color(v.hex, (i - 1) * v.intensity)

    api.nvim_set_hl(v.ns, "hue" .. dark:sub(2), { bg = dark, fg = dark })
    api.nvim_set_hl(v.ns, "hue" .. light:sub(2), { bg = light, fg = light })

    local light_block = {
      blockstr,
      "hue" .. light:sub(2),
      function()
        v.new_hex = light:sub(2)
        redraw(v.buf, { "footer" })
      end,
    }

    local dark_block = {
      blockstr,
      "hue" .. dark:sub(2),
      function()
        v.new_hex = dark:sub(2)
        redraw(v.buf, { "footer" })
      end,
    }

    table.insert(light_blocks, light_block)
    table.insert(dark_blocks, 1, dark_block)
  end

  return { light_blocks, light_blocks, dark_blocks, dark_blocks }
end

-------------------------- intensity status & column toggler -----------------------------------
local update_palette_cols = function(n)
  v.blocklen = n == 12 and 3 or 6
  v.palette_cols = n
  redraw(v.buf, { "palettes", "intensity" })
end

M.intensity = function()
  return {
    {},

    {
      { "Intensity : " .. v.intensity .. (v.intensity == 10 and "" or " ") },
      { "         " },

      {
        "",
        v.palette_cols == 12 and "Function" or "LineNr",
        function()
          update_palette_cols(12)
        end,
      },

      { "  " },

      {
        "",
        v.palette_cols == 6 and "Function" or "LineNr",
        function()
          update_palette_cols(6)
        end,
      },

      { "  Columns" },
    },
  }
end

---------------------------------- slider -------------------------------------------
local handle_slider = function()
  local col = api.nvim_win_get_cursor(0)[2]
  local percentage = math.floor((col - 1) / v.w_with_pad * 100)
  v.intensity = math.floor(percentage < 0 and 0 or percentage / v.step)
  redraw(v.buf, { "slider", "intensity", "palettes" })
end

M.slider = function()
  local col = api.nvim_win_get_cursor(0)[2]

  col = col - v.xpad
  col = col < 0 and v.w_with_pad / 2 or col

  if col > v.w_with_pad then
    col = v.w_with_pad
  end

  local inactive = v.w_with_pad - col

  return {
    {
      { string.rep("━", col), "NvimInternalError", handle_slider },
      { string.rep("━", inactive), "LineNr", handle_slider },
    },
  }
end

local function save_color()
  v.close()
  local line = api.nvim_get_current_line()
  line = line:gsub(v.hex, v.new_hex)
  api.nvim_set_current_line(line)
end

M.footer = function()
  local col_len = 9

  local function gen_padding(n)
    return { string.rep(" ", n or 1) }
  end

  local space = gen_padding()
  local underline = { string.rep("-", col_len), "LineNr" }

  api.nvim_set_hl(v.ns, "hex1", { fg = "#" .. v.hex })
  api.nvim_set_hl(v.ns, "hex2", { fg = "#" .. v.new_hex })

  local results = {
    {},
    {
      { "Old Color" },
      space,
      space,
      { "New Color" },
      gen_padding(6),
      { "┌" .. string.rep("─", 8) .. "┐", "Function", save_color },
    },

    {
      underline,
      space,
      space,
      underline,
      gen_padding(6),
      { "│", "Function", save_color },
      { " 󰆓 Save ", "Function", save_color },
      { "│", "Function", save_color },
    },

    {
      { "󱓻 ", "hex1" },
      { "#" .. v.hex },
      space,
      space,
      { "󱓻 ", "hex2" },
      { "#" .. v.new_hex },
      gen_padding(6),
      { "└" .. string.rep("─", 8) .. "┘", "Function", save_color },
    },
    {},

    -- { { string.rep("─", v.w_with_pad), "LineNr" } },
    -- { { string.rep("─", v.w_with_pad), "LineNr" } },
  }

  return results
end

return M
