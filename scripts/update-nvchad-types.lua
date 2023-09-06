local normalize = vim.fs.normalize
local fnamemodify = vim.fn.fnamemodify
-- local nvchad_types_fp = vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h"))
local nvchad_types_fp = fnamemodify(normalize(debug.getinfo(1, "S").source:sub(2)), ":p:h:h") .. "/nvchad_types"
local base46_fp = fnamemodify(normalize(debug.getinfo(require("base46").compile, "S").source:sub(2)), ":p:h")

local write_file = function(path, content)
  local file = assert(io.open(path, "w+"))

  file:write(content)
  file:close()
end

local get_base_name = function(path)
  return fnamemodify(normalize(path), ":t:r")
end

local gen_themes = function()
  local contents = {
    "---@meta",
    "--- Don't edit or require this file",
    "error(\"Requring a meta file\")",
    "",
    "---@type ThemeName",
    "vim.g.nvchad_theme = 'onedark'",
    "",
    "---@alias ThemeName",
    "",
    "---@class ChangedTheme",
    "--- changes for all themes. Has lower precedence than theme-specific changes",
    "---@field all ThemeTable"
  }


  for name, _ in vim.fs.dir(
    normalize(base46_fp .. "/themes")
  ) do
    local theme_name = get_base_name(name)
    table.insert(contents, 9, "---| '\"" .. theme_name .. "\"'")
    table.insert(contents,
      string.format("---@field %s ThemeTable # Changes for %s theme",
        theme_name:match("[^%l%u_]") and '["' .. theme_name .. '"]' or theme_name, theme_name))
  end

  write_file(
    nvchad_types_fp .. "/themes.lua",
    table.concat(contents, "\n")
  )
end

local gen_highlights = function()
  local contents = {
    "---@meta",
    "",
    "--- Don't edit or require this file",
    "error(\"Requring a meta file\")",
    "",
    "---@class HLGroups",
    "",
    "---@class ExtendedHLGroups",
    "",
    "---@class Base46HLGroupsList: HLGroups, ExtendedHLGroups",
    "",
    "---@alias ExtendedModules",
  }
  local hlgroups = {}
  local ignored_files = {
    ["treesitter"] = true,
    ["statusline"] = true,
  }

  local mapped_name = {
    ["tbline"] = "tabufline",
  }

  for name, _ in vim.fs.dir(
    normalize(base46_fp .. "/extended_integrations")
  ) do
    local base_name = get_base_name(name)
    ---@type table<string, Base46HLGroups>
    local groups = require("base46.extended_integrations." .. base_name)
    table.insert(contents, string.format("---| \"'%s'\"", base_name))
    for hlname, _ in vim.spairs(groups) do
      if not hlgroups[hlname] then
        hlgroups[hlname] = base_name
      end
    end
  end

  for name, integration in vim.spairs(hlgroups) do
    if string.sub(name, 1, 1) == "@" then
      table.insert(contents, 9,
        string.format("---@field [\"'%s'\"] Base46HLGroups # highlight group for %s", name,
          mapped_name[integration] or integration))
    else
      table.insert(contents, 9,
        string.format("---@field %s Base46HLGroups # highlight group for %s", name,
          mapped_name[integration] or integration))
    end
  end

  hlgroups = {}

  for name, _ in vim.fs.dir(
    normalize(base46_fp .. "/integrations")
  ) do
    local base_name = get_base_name(name)
    ---@type table<string, Base46HLGroups>
    local groups = require("base46.integrations." .. base_name)
    if not ignored_files[base_name] then
      for hlname, _ in vim.spairs(groups) do
        if not hlgroups[hlname] then
          hlgroups[hlname] = base_name
        end
      end
    end
  end

  for name, integration in vim.spairs(hlgroups) do
    if string.sub(name, 1, 1) == "@" then
      table.insert(contents, 7,
        string.format("---@field [\"'%s'\"] Base46HLGroups # highlight group for %s", name,
          mapped_name[integration] or integration))
    else
      table.insert(contents, 7,
        string.format("---@field %s Base46HLGroups # highlight group for %s", name,
          mapped_name[integration] or integration))
    end
  end

  write_file(
    nvchad_types_fp .. "/all_hl_groups.lua",
    table.concat(contents, "\n")
  )
end

gen_themes()

gen_highlights()
