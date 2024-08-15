local api = vim.api
local v = require "nvchad.huefy.state"
local redraw = require("nvchad.extmarks").redraw
local lighten = require("base46.colors").change_hex_lightness
local change_hue = require("base46.colors").change_hex_hue
local rgb2hex = require("base46.colors").rgb2hex
local hex2rgb_ratio = require("base46.colors").hex2rgb_ratio
local M = {}

local separator = { { string.rep("-", v.w_with_pad), "LineNr" } }

local redraw_all = function()
  redraw(v.tools_buf, "all")
  redraw(v.palette_buf, "all")
end

------------------------------- color blocks ----------------------------------------
local function gen_colors(hex, row, type)
  local blocks = {}
  local abc = type == "dark" and -1 or 12

  for i = 1, 12, 1 do
    local color = lighten(hex or v.new_hex, (abc - i) * row * 1.45)
    local hlgroup = "hue" .. color:sub(2)

    local block = {
      "   ",
      hlgroup,
      function()
        v.new_hex = color:sub(2)
        v.rgb.r, v.rgb.g, v.rgb.b = hex2rgb_ratio(v.new_hex)
        redraw_all()
      end,
    }

    api.nvim_set_hl(v.ns, hlgroup, { bg = color })

    table.insert(blocks, block)
  end

  return blocks
end

M.palettes = function()
  local blocks = {}

  for row = 1, 3, 1 do
    table.insert(blocks, 1, gen_colors(nil, row))
  end

  local lastcolor = blocks[#blocks][1][2]:sub(4)

  for row = 1, 4, 1 do
    table.insert(blocks, gen_colors(lastcolor, row, "dark"))
  end

  table.insert(blocks, 1, {})
  table.insert(blocks, {})
  return blocks
end

M.hue = function()
  local result = {}

  for i = 1, 36, 1 do
    local new_color = change_hue(v.new_hex, i * 2)
    local hlgroup = "hue" .. new_color:sub(2)

    local block = {
      " ",
      hlgroup,
      function()
        v.new_hex = new_color:sub(2)
        v.rgb.r, v.rgb.g, v.rgb.b = hex2rgb_ratio(v.new_hex)
        redraw_all()
      end,
    }

    table.insert(result, block)
    api.nvim_set_hl(v.ns, hlgroup, { bg = new_color })
  end

  return { { { "Hue" } }, separator, result }
end

local function save_color()
  v.close()
  local line = api.nvim_get_current_line()
  line = line:gsub(v.new_hex, v.new_hex)
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
  }

  return results
end

---------------------------------- slider -------------------------------------------
local slider = function(opts)
  local line = {}

  if opts.txt then
    table.insert(line, { opts.txt .. "  " })
    opts.w = opts.w - vim.fn.strwidth(line[1][1]) - 8
  end

  local active_len = math.floor((opts.val / 100) * opts.w)
  local ratio = math.floor((active_len / opts.w) * 100)

  for i = 1, opts.w, 1 do
    local hlgroup = i <= active_len and opts.hlon or opts.hloff

    local char = {
      i == active_len and " " or "━",
      -- "━",
      hlgroup,
      function()
        opts.onclick(i)
      end,
    }

    table.insert(line, char)
  end

  table.insert(line, { "  " .. ratio .. " %", "Comment" })

  return line
end

M.rgb_slider = function()
  local lines = {}
  local sliders_info = { Red = "r", Green = "g", Blue = "b" }

  for key, val in pairs(sliders_info) do
    local ui = slider {
      txt = val:upper(),
      w = v.tools_with_pad,
      val = math.floor(v.rgb[val]),
      hlon = "HueSlider" .. key,
      hloff = "HueSliderGrey",
      onclick = function(step)
        v.rgb[val] = step * 4
        v.new_hex = rgb2hex(v.rgb.r, v.rgb.g, v.rgb.b):sub(2)
        redraw_all()
      end,
    }

    table.insert(lines, ui)
  end

  return lines
end

return M
