local M = {}
local api = vim.api
local utils = require "nvchad.color.utils"
local ns = api.nvim_create_namespace "ColorLighten"
local set_extmark = api.nvim_buf_set_extmark
local get_extmarks = api.nvim_buf_get_extmarks
local lighten_hex = require("base46.colors").change_hex_lightness
local blocklen = 6

local function color_infos(hex, intensity, n)
  local light_blocks = {}
  local dark_blocks = {}

  for i = 1, n, 1 do
    local dark_hue = lighten_hex(hex, -1 * (i - 1) * intensity)
    local light_hue = lighten_hex(hex, (i - 1) * intensity)

    api.nvim_set_hl(ns, "hue" .. dark_hue:sub(2), { bg = dark_hue, fg = dark_hue })
    api.nvim_set_hl(ns, "hue" .. light_hue:sub(2), { bg = light_hue, fg = light_hue })

    table.insert(dark_blocks, { string.rep(" ", blocklen), "hue" .. dark_hue:sub(2) })
    table.insert(light_blocks, { string.rep(" ", blocklen), "hue" .. light_hue:sub(2) })
  end

  return { light_blocks, dark_blocks }
end

local function palette_lines(hex, intensity, palette_cols, sep_len)
  local palettes = color_infos(hex, intensity, palette_cols)

  local lines = {
    {},
    { { "Lightened color by " .. intensity } },
    { { string.rep("-", sep_len), "Comment" } },

    palettes[1],
    palettes[1],

    {},
    { { "Darkened color by " .. intensity } },
    { { string.rep("-", sep_len), "Comment" } },

    palettes[2],
    palettes[2],

    {},
    {
      { "Intensity : " .. intensity },
      { "         " },
      { "  ", palette_cols == 12 and  "@function" or "Comment" },
      { " ", palette_cols == 6 and "@function" or "Comment" },
      { " Columns" },
    },
  }

  return lines
end

local extmark_ids = {}
local slider_id

local draw_blocks = function(buf, lines, xpad)
  for i, virt_txts in ipairs(lines) do
    local opts = { virt_text_pos = "overlay", virt_text = virt_txts, id = extmark_ids[i] }
    local extmark_id = set_extmark(buf, ns, i - 1, 0 + xpad, opts)
    if #extmark_ids < #lines then
      table.insert(extmark_ids, extmark_id)
    end
  end
end

local slider = function(buf, w, lastline, xpad, col)
  local a = { { string.rep("━", col), "Sh_ActiveSlider" }, { string.rep("━", w - col), "comment" } }
  local opts = { virt_text_pos = "overlay", virt_text = a, id = slider_id }
  slider_id = set_extmark(buf, ns, lastline, 0 + xpad, opts)
end

local results = function(hex, new_hex, pad)
  local col_len = 9

  local function gen_padding(n)
    return { string.rep(" ", pad * (n or 1)) }
  end

  local padding = gen_padding()

  api.nvim_set_hl(ns, "huefg_" .. hex, { fg = "#" .. hex })
  api.nvim_set_hl(ns, "huefg_" .. new_hex, { fg = "#" .. new_hex })
  local underline = { string.rep("-", col_len), "Comment" }

  local results = {
    {},
    {
      padding,
      { "Old Color" },
      padding,
      { "New Color" },
      gen_padding(3),
      { "┌" .. string.rep("─", 8) .. "┐", "@string" },
    },
    { padding, underline, padding, underline, gen_padding(3), { "│" .. " 󰆓 Save " .. "│", "@string" } },

    {
      padding,
      { "󱓻 ", "huefg_" .. hex },
      { "#" .. hex },
      padding,
      { "󱓻 ", "huefg_" .. new_hex },
      { "#" .. new_hex },
      gen_padding(3),
      { "└" .. string.rep("─", 8) .. "┘", "@string" },
    },
  }
  return results
end

local result_id

M.open = function()
  print(ns)
  local hex = utils.hex_on_cursor()

  if not hex then
    print "not a hex color!"
    return
  end

  local xpad = 2
  local palette_cols = 6
  local h = 18
  local w = palette_cols * blocklen + (2 * xpad)
  local w_with_pad = w - (2 * xpad)
  local intensity = 5
  local step = 10
  local new_hex = hex

  local buf = api.nvim_create_buf(false, true)

  local win = api.nvim_open_win(buf, true, {
    row = 1,
    col = 0,
    width = w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = { { " 󱥚 Color Shades ", "floatTitle" } },
    title_pos = "center",
  })
  api.nvim_win_set_hl_ns(win, ns)

  vim.bo[buf].ft = "colortool"
  api.nvim_set_hl(ns, "FloatBorder", { link = "NvColorBorder" })

  local function toggle_palette_cols()
    blocklen = blocklen == 6 and 3 or 6
    palette_cols = palette_cols == 12 and 6 or 12
  end

  -- set empty lines to make all cols/rows available
  local empty_lines = {}

  for i = 1, h, 1 do
    table.insert(empty_lines, string.rep(" ", w))
  end

  api.nvim_buf_set_lines(buf, 0, -1, true, empty_lines)

  -- set lines & highlights
  local lines = palette_lines(hex, intensity, palette_cols, w_with_pad)
  draw_blocks(buf, lines, xpad)

  local slider_row = #lines

  slider(buf, w_with_pad, slider_row, xpad, w_with_pad / 2)

  result_id = set_extmark(buf, ns, slider_row, 0 + xpad, {
    virt_text_pos = "overlay",
    virt_lines = results(hex, hex, xpad),
  })

  api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local cursor_pos = api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1] - 1, cursor_pos[2]

      if row == slider_row then
        local percentage = math.floor((col - 1) / w_with_pad * 100)
        intensity = math.floor(percentage / step)

        lines = palette_lines(hex, intensity, palette_cols, w_with_pad)
        draw_blocks(buf, lines, xpad)
        slider(buf, w_with_pad, slider_row, xpad, col - 1)
      end

      if row == slider_row - 1 then
        toggle_palette_cols()
        lines = palette_lines(hex, intensity, palette_cols, w_with_pad)

        draw_blocks(buf, lines, xpad)
      end

      for i, value in ipairs(lines[row + 1] or {}) do
        if ((i - 1) * blocklen) > col and col < (i * blocklen) then
          new_hex = value[2]:sub(4)

          set_extmark(buf, ns, slider_row, 0 + xpad, {
            virt_text_pos = "overlay",
            virt_lines = results(hex, new_hex, xpad),
            id = result_id,
          })

          return
        end
      end
    end,
  })
end

return M
