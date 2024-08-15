local api = vim.api
local v = require "nvchad.huefy.state"
local redraw = require("nvchad.extmarks").redraw
local lighten = require("base46.colors").change_hex_lightness
local change_hue = require("base46.colors").change_hex_hue
local rgb2hex = require("base46.colors").rgb2hex
local change_saturation = require("base46.colors").change_hex_saturation
local slider = require("nvchad.huefy.components").slider
local checkbox = require("nvchad.huefy.components").checkbox

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
    local color = lighten(hex or v.new_hex, (abc - i) * row * 1.3)
    local hlgroup = "hue" .. color:sub(2)

    local block = {
      "   ",
      hlgroup,
      function()
        v.set_hex(color)
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

  for row = 1, 4, 1 do
    table.insert(blocks, 1, gen_colors(nil, row))
  end

  local lastcolor = blocks[#blocks][1][2]:sub(4)

  for row = 1, 5, 1 do
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
        v.set_hex(new_color)
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

M.rgb_slider = function()
  local rgb = v.sliders
  local lines = {}
  local sliders_info = { { "r", "Red" }, { "g", "Green" }, { "b", "Blue" } }

  for _, val in ipairs(sliders_info) do
    local ui = slider {
      txt = val[1]:upper(),
      w = v.tools_with_pad,
      val = math.floor(rgb[val[1]]),
      hlon = "HueSlider" .. val[2],
      hloff = "HueSliderGrey",
      ratio_txt = true,
      onclick = function(step)
        rgb[val[1]] = step
        v.new_hex = rgb2hex(rgb.r, rgb.g, rgb.b):sub(2)
        redraw_all()
      end,
    }

    table.insert(lines, ui)
  end

  return lines
end


M.saturation_slider = function()
  return {
    {},

    {
      { "  Contrast" },

      { string.rep(" ", 15) },

      checkbox {
        txt = "Vibrant",
        hlon = "String",
        active = v.contrast_mode == "vibrant",
        onclick = function()
          v.contrast_mode = v.contrast_mode == "dim" and "vibrant" or "dim"

          local mm = v.contrast_mode == "dim" and -1 or 1
          local color = change_saturation("#" .. v.new_hex, v.sliders.saturation * mm)

          v.set_hex(color)
          redraw_all()
        end,
      },
    },

    slider {
      w = v.tools_with_pad,
      val = v.sliders.saturation,
      hlon = "Normal",
      hloff = "HueSliderGrey",
      ratio_txt = false,
      thumb = true,
      onclick = function(step)
        local mm = v.contrast_mode == "dim" and -1 or 1
        local color = change_saturation("#" .. v.new_hex, mm * step)
        v.sliders.saturation = step
        v.set_hex(color)
        redraw_all()
      end,
    },
  }
end

M.lightness_slider = function()
  local handle_click = function(step)
    local mm = v.lightness_mode == "dark" and -1 or 1
    local color = lighten("#" .. v.hex, (mm * step)/2)
    v.sliders.lightness = step

    v.set_hex(color)
    redraw_all()
  end

  return {
    {},

    {
      { "  Lightness" },

      { string.rep(" ", 14) },

      checkbox {
        txt = "Darken",
        hlon = "String",
        active = v.lightness_mode == "dark",
        onclick = function()
          v.lightness_mode = v.lightness_mode == "dark" and "light" or "dark"
          handle_click(v.sliders.lightness)
        end,
      },
    },

    slider {
      w = v.tools_with_pad,
      val = v.sliders.lightness,
      hlon = "Normal",
      hloff = "HueSliderGrey",
      ratio_txt = false,
      thumb = true,
      onclick = function(step)
        handle_click(step)
      end,
    },
  }
end

return M
