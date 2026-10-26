local M = {}
local api = vim.api
local state = require "nvchad.themes.state"

local get_theme_colors = function(name)
  local ok, theme = pcall(require, "base46.themes." .. name)

  if not ok then
    theme = require("themes." .. name)
  end

  return theme.base_16
end

local hls_done = {}

local theme_hls = function(name, with_bg)
  local prefix = "NvT" .. name

  if not hls_done[name] then
    local theme_colors = get_theme_colors(name)
    local theme_bg = with_bg and theme_colors.base00 or nil

    api.nvim_set_hl(state.ns, prefix .. "line", { bg = theme_bg, fg = theme_colors.base07 })
    api.nvim_set_hl(state.ns, prefix .. "name", { fg = theme_colors.base07, bg = theme_bg })

    for color_i, color in ipairs(state.order) do
      api.nvim_set_hl(state.ns, prefix .. color_i, { fg = theme_colors[color], bg = theme_bg })
    end

    hls_done[name] = true
  end

  return prefix
end

M.compact = function()
  local result = {}
  local list = state.themes_shown

  for i = 1, #list, 1 do
    local name = list[i]
    local prefix = theme_hls(name, true)
    local linehl = prefix .. "line"
    local themeNameHl = prefix .. "name"

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap + 1
    local line = { { " " .. name .. string.rep(" ", padding), themeNameHl } }

    -- colored icons
    for color_i = 1, #state.order do
      table.insert(line, { state.icon, prefix .. color_i })
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
    local prefix = theme_hls(name, true)
    local linehl = prefix .. "line"
    local themeNameHl = prefix .. "name"

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap + 4

    local active = i == state.index
    local active_icon = active and " " or ""
    padding = active and padding - 2 or padding

    local line = { { "  " .. name .. active_icon .. string.rep(" ", padding), themeNameHl } }

    -- colored icons
    for color_i = 1, #state.order do
      table.insert(line, { state.icon, prefix .. color_i })
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
    local prefix = theme_hls(name, false)

    -- theme name + palette colors
    local padding = state.longest_name - #name + state.word_gap

    local active = i == state.index
    local active_icon = active and " " or ""
    local active_hl = active and "ExBlue" or "Normal"
    padding = active and padding - 2 or padding

    local line = { { name .. active_icon .. string.rep(" ", padding), active_hl } }

    -- colored icons
    for color_i = 1, #state.order do
      table.insert(line, { state.icon, prefix .. color_i })
    end

    table.insert(result, line)

    if i ~= last_index then
      local active_border = (active or state.index == i + 1)
      active_hl = active_border and "ExBlue" or "linenr"
      local icon = active_border and "─" or "-"
      table.insert(result, { { string.rep(icon, state.w - 2), active_hl } })
    end
  end

  return result
end

return M
