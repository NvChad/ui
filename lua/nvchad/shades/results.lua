local api = vim.api
local v = require "nvchad.shades.state"
local set_extmark = api.nvim_buf_set_extmark

local M = {}

local result_id

local results_ui = function()
  local col_len = 9

  local function gen_padding(n)
    return { string.rep(" ", v.xpad * (n or 1)) }
  end

  local space = gen_padding()

  api.nvim_set_hl(v.ns, "huefg_" .. v.hex, { fg = "#" .. v.hex })
  api.nvim_set_hl(v.ns, "huefg_" .. v.new_hex, { fg = "#" .. v.new_hex })
  local underline = { string.rep("-", col_len), "Comment" }

  local results = {
    {},
    {
      space,
      { "Old Color" },
      space,
      { "New Color" },
      gen_padding(3),
      { "┌" .. string.rep("─", 8) .. "┐", "Comment" },
    },

    {
      space,
      underline,
      space,
      underline,
      gen_padding(3),
      { "│", "Comment" },
      { " 󰆓 Save " },
      { "│", "Comment" },
    },

    {
      space,
      { "󱓻 ", "huefg_" .. v.hex },
      { "#" .. v.hex },
      space,
      { "󱓻 ", "huefg_" .. v.new_hex },
      { "#" .. v.new_hex },
      gen_padding(3),
      { "└" .. string.rep("─", 8) .. "┘", "Comment" },
    },
  }
  return results
end

M.draw = function()
  result_id = set_extmark(v.buf, v.ns, #v.palette_lines, 0 + v.xpad, {
    virt_text_pos = "overlay",
    virt_lines = results_ui(),
    id = result_id,
  })
end

return M
