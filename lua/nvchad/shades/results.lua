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

  local padding = gen_padding()

  api.nvim_set_hl(v.ns, "huefg_" .. v.hex, { fg = "#" .. v.hex })
  api.nvim_set_hl(v.ns, "huefg_" .. v.new_hex, { fg = "#" .. v.new_hex })
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
      { "󱓻 ", "huefg_" .. v.hex },
      { "#" .. v.hex },
      padding,
      { "󱓻 ", "huefg_" .. v.new_hex },
      { "#" .. v.new_hex },
      gen_padding(3),
      { "└" .. string.rep("─", 8) .. "┘", "@string" },
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
