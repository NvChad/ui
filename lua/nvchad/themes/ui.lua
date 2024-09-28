local M = {}
local api = vim.api
local state = require "nvchad.themes.state"

M.compact = function()
  local result = {}
  local list = state.themes_shown

  for i = 1, #list, 1 do
    local name = list[i]

    local theme_colors = require("base46.themes." .. name).base_16
    local theme_bg = theme_colors.base00

    local linehl = "NvT" .. i .. "line"
    api.nvim_set_hl(state.ns, linehl, { bg = theme_bg, fg = theme_colors.base07 })

    local themeNameHl = "NvT" .. i .. "name"
    api.nvim_set_hl(state.ns, themeNameHl, { fg = theme_colors.base07, bg = theme_bg })

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap + 1
    local line = { { " " .. name .. string.rep(" ", padding), themeNameHl } }

    -- colored icons
    for color_i, color in ipairs(state.order) do
      local hl = "NvT" .. i .. color_i
      api.nvim_set_hl(state.ns, hl, { fg = theme_colors[color], bg = theme_bg })
      table.insert(line, { state.icon, hl })
    end

    -- active indicator
    local active_row = i == state.index
    local thumb = active_row and "┃" or "│"
    table.insert(line, { " " .. thumb, active_row and "ExBlue" or "NScrollbarOff" })
    table.insert(result, line)
  end

  return result
end

M.flat = function()
  local result = {}
  local list = state.themes_shown

  for i = 1, #list, 1 do
    local name = list[i]

    local theme_colors = require("base46.themes." .. name).base_16
    local theme_bg = theme_colors.base00

    local linehl = "NvT" .. i .. "line"
    api.nvim_set_hl(state.ns, linehl, { bg = theme_bg, fg = theme_colors.base07 })

    local themeNameHl = "NvT" .. i .. "name"
    api.nvim_set_hl(state.ns, themeNameHl, { fg = theme_colors.base07, bg = theme_bg })

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap

    local active = i == state.index
    local active_icon = active and " " or ""
    padding = active and padding - 2 or padding

    local line = { { "  " .. name .. active_icon .. string.rep(" ", padding), themeNameHl } }

    -- colored icons
    for color_i, color in ipairs(state.order) do
      local hl = "NvT" .. i .. color_i
      api.nvim_set_hl(state.ns, hl, { fg = theme_colors[color], bg = theme_bg })
      table.insert(line, { state.icon, hl })
    end

    table.insert(line, { "  ", linehl })
    table.insert(result, { { string.rep(" ", state.w - 2), linehl } })
    table.insert(result, line)
    table.insert(result, { { string.rep(" ", state.w - 2), linehl } })
  end

  return result
end

M.bordered = function()
  local result = {}
  local list = state.themes_shown
  local last_index = #list

  for i = 1, #list, 1 do
    local name = list[i]

    local theme_colors = require("base46.themes." .. name).base_16

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap + 4

    local active = i == state.index
    local active_icon = active and " " or ""
    padding = active and padding - 2 or padding

    local line = { { name .. active_icon .. string.rep(" ", padding) } }

    -- colored icons
    for color_i, color in ipairs(state.order) do
      local hl = "NvT" .. i .. color_i
      api.nvim_set_hl(state.ns, hl, { fg = theme_colors[color] })
      table.insert(line, { state.icon, hl })
    end

    table.insert(result, line)

    if i ~= last_index then
      local active_border = (active or state.index == i + 1)
      local active_hl = active_border and "ExBlue" or "linenr"
      local icon = active_border and "─" or "-"
      table.insert(result, { { string.rep(icon, state.w - 2), active_hl } })
    end
  end

  return result
end

return M
