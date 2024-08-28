local api = vim.api
local v = require "nvchad.huefy.state"
local redraw = require("nvchad.extmarks").redraw
local lighten = require("base46.colors").change_hex_lightness
local change_hue = require("base46.colors").change_hex_hue
local rgb2hex = require("base46.colors").rgb2hex
local change_saturation = require("base46.colors").change_hex_saturation
local ui = require("nvchad.extmarks_ui")
local hex2complementary = require("base46.colors").hex2complementary

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

    api.nvim_set_hl(v.paletteNS, hlgroup, { bg = color })

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
    local new_color = change_hue(v.new_hex, i * v.hue_intensity)
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
    api.nvim_set_hl(v.paletteNS, hlgroup, { bg = new_color })
  end

  return {
    {
      { "Hue Variants" },
      { string.rep(" ", 10) },

      {
        "",
        "Function",
        function()
          v.hue_intensity = v.hue_intensity + 1
          redraw(v.palette_buf, { "hue" })
        end,
      },

      { "  " },

      {
        "",
        "Comment",
        function()
          v.hue_intensity = v.hue_intensity - 1
          redraw(v.palette_buf, { "hue" })
        end,
      },

      { "  Step: " .. v.hue_intensity },
    },

    separator,

    result,
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

  api.nvim_set_hl(v.paletteNS, "hex1", { fg = "#" .. v.hex })
  api.nvim_set_hl(v.paletteNS, "hex2", { fg = "#" .. v.new_hex })

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
    local mark = ui.slider {
      txt = val[1]:upper(),
      w = v.tools_with_pad,
      val = math.floor(rgb[val[1]]),
      hlon = "HuefySlider" .. val[2],
      ratio_txt = true,
      onclick = function(step)
        rgb[val[1]] = step
        v.new_hex = rgb2hex(rgb.r, rgb.g, rgb.b):sub(2)
        redraw(v.tools_buf, { "rgb_slider", "suggested_colors" })
        redraw(v.palette_buf, "all")
      end,
    }

    table.insert(lines, mark)
  end

  return lines
end

M.saturation_slider = function()
  local function handle_click(step)
    local mm = v.saturation_mode == "dim" and -1 or 1
    local color = change_saturation("#" .. v.hex, v.sliders.saturation * mm)
    v.sliders.saturation = step
    v.set_hex(color)
    redraw(v.tools_buf, { "saturation_slider", "rgb_slider", "suggested_colors" })
    redraw(v.palette_buf, "all")
  end

  return {
    {},

    {
      { "󰌁  Saturation" },

      { string.rep(" ", 14) },

      ui.checkbox {
        txt = "Invert",
        hlon = "String",
        active = v.saturation_mode == "vibrant",
        onclick = function()
          v.saturation_mode = v.saturation_mode == "dim" and "vibrant" or "dim"
          handle_click(v.sliders.saturation)
        end,
      },
    },

    ui.slider {
      w = v.tools_with_pad,
      val = v.sliders.saturation,
      hlon = "Normal",
      ratio_txt = false,
      thumb = true,
      onclick = handle_click,
    },
  }
end

M.lightness_slider = function()
  local handle_click = function(step)
    local mm = v.lightness_mode == "dark" and -1 or 1
    local color = lighten("#" .. v.hex, (mm * step) / 2)
    v.sliders.lightness = step

    v.set_hex(color)
    redraw(v.tools_buf, { "lightness_slider", "rgb_slider", "suggested_colors" })
    redraw(v.palette_buf, "all")
  end

  return {
    {},

    {
      { "󰖨  Lightness" },

      { string.rep(" ", 15) },

      ui.checkbox {
        txt = "Darken",
        hlon = "String",
        active = v.lightness_mode == "dark",
        onclick = function()
          v.lightness_mode = v.lightness_mode == "dark" and "light" or "dark"
          handle_click(v.sliders.lightness)
        end,
      },
    },

    ui.slider {
      w = v.tools_with_pad,
      val = v.sliders.lightness,
      hlon = "Normal",
      ratio_txt = false,
      thumb = true,
      onclick = handle_click,
    },
  }
end

M.suggested_colors = function()
  local qty = 36
  local colors = hex2complementary(v.new_hex, qty)

  local line1 = {}
  local line2 = {}

  for i, color in ipairs(colors) do
    local hlgroup = "coo" .. color:sub(2)
    api.nvim_set_hl(v.toolsNS, hlgroup, { fg = color })

    local virt_text = {
      "󱓻",
      hlgroup,
      function()
        v.set_hex(color)
        redraw_all()
      end,
    }

    local space = { " " }

    if i <= qty / 2 then
      table.insert(line1, virt_text)
      table.insert(line1, space)
    else
      table.insert(line2, virt_text)
      table.insert(line2, space)
    end
  end

  return {
    {},
    { { "󱥚  Complementary Colors" } },
    separator,

    line1,
    line2,
  }
end

return M
