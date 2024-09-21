local M = {}
local state = require "nvchad.themes.state"
local api = vim.api

M.themes = function()
  local result = {}
  local list = state.themes_shown

  for i = 1, #list, 1 do
    local name = list[i]

    local theme_colors = require("base46.themes." .. name).base_16
    local theme_bg = theme_colors.base00

    local linehl = "NvT" .. i .. "line"
    api.nvim_set_hl(state.ns, linehl, { bg = theme_bg })

    local themeNameHl = "NvT" .. i .. "name"
    api.nvim_set_hl(state.ns, themeNameHl, { fg = theme_colors.base07, bg = theme_bg })

    local padding = state.longest_name - #name + state.word_gap + 1

    local line = { { " " .. name .. string.rep(" ", padding), themeNameHl } }

    for color_i, color in ipairs(state.order) do
      local hl = "NvT" .. i .. color_i
      api.nvim_set_hl(state.ns, hl, { fg = theme_colors[color], bg = theme_bg })
      table.insert(line, { "󱓻 ", hl })
    end

    local active_row = i == state.index
    local thumb = active_row and "┃" or "│"

    table.insert(line, { " " .. thumb, active_row and "ExBlue" or "NScrollbarOff" })
    table.insert(result, line)
  end

  return result
end

return M
