local M = {}
local api = vim.api
local utils = require "nvchad.color.utils"

local palette = require "nvchad.shades.palette"
local slider = require "nvchad.shades.slider"
local results = require "nvchad.shades.results"

local set_opt = api.nvim_set_option_value

local v = require "nvchad.shades.state"
v.ns = api.nvim_create_namespace "NvShades"

M.open = function()
  v.hex = utils.hex_on_cursor()

  if not v.hex then
    print "not a hex color!"
    return
  end

  local h = 15
  v.new_hex = v.hex
  v.buf = api.nvim_create_buf(false, true)

  local win = api.nvim_open_win(v.buf, true, {
    row = 1,
    col = 0,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = { { " 󱥚 Color Shades ", "floatTitle" } },
    title_pos = "center",
  })

  api.nvim_win_set_hl_ns(win, v.ns)
  api.nvim_set_hl(v.ns, "FloatBorder", { link = "NvColorBorder" })

  -- set empty lines to make all cols/rows available
  local empty_lines = {}

  for _ = 1, h, 1 do
    table.insert(empty_lines, string.rep(" ", v.w))
  end

  api.nvim_buf_set_lines(v.buf, 0, -1, true, empty_lines)

  palette.draw()
  slider.draw(v.w_with_pad / 2)
  results.draw()

  -------------- interactivity --------------------
  api.nvim_create_autocmd("CursorMoved", {
    buffer = v.buf,
    callback = function()
      local cursor_pos = api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]
      local slider_row = #v.palette_lines + 1

      -- mode switcher
      if row == 2 then
        v.mode = v.mode == "lightner" and "saturater" or "lightner"
        palette.draw()
      end

      -- slider interactivity
      if row == slider_row then
        local percentage = math.floor((col - 1) / v.w_with_pad * 100)
        v.intensity = math.floor(percentage < 0 and 0 or percentage / v.step)
        palette.draw()
        slider.draw(col < v.xpad and 0 or col - 2)
      end

      -- column toggler, -1 cuz its above slider!
      if row == slider_row - 1 and col > (v.w_with_pad / 2) then
        slider.toggle_shade_cols()
        palette.draw()
      end

      -- make color blocks clickable
      if vim.tbl_contains(v.color_blocks_rows, row) then
        local col_pos = math.floor((col - 2) / v.blocklen) + 1

        if col_pos > 0 and col_pos <= v.palette_cols then
          local shade_row = v.palette_lines[row]
          v.new_hex = shade_row[col_pos][2]:sub(4)
          results.draw()
        end
      end
    end,
  })

  ----------------- keymaps --------------------------
  vim.keymap.set("n", "q", ":q<cr>", { buffer = v.buf })
  vim.keymap.set("n", "<esc>", ":q<cr>", { buffer = v.buf })

  set_opt("modifiable", false, { buf = v.buf })
end

return M
