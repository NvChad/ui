local M = {}
local fn = vim.fn

M.list_themes = function()
  local default_themes = vim.fn.readdir(vim.fn.stdpath "data" .. "/lazy/base46/lua/base46/themes")
  local custom_themes = vim.loop.fs_stat(fn.stdpath "config" .. "/lua/custom/themes")

  if custom_themes and custom_themes.type == "directory" then
    local themes_tb = fn.readdir(fn.stdpath "config" .. "/lua/custom/themes")
    for _, value in ipairs(themes_tb) do
      table.insert(default_themes, value)
    end
  end

  for index, theme in ipairs(default_themes) do
    default_themes[index] = theme:match "(.+)%..+"
  end

  return default_themes
end

M.change_key_val = function(key, val)
  local chadrc = vim.fn.stdpath "config" .. "/lua/custom/" .. "chadrc.lua"
  local file = io.open(chadrc, "r")

  local content = file:read "*all"
  local pattern = "(%s*" .. key .. "%s*=%s*)([^,]+)"

  val = (type(val) == "boolean" and tostring(val)) or ('"' .. val .. '"')

  local updated_content = content:gsub(pattern, "%1" .. val)

  file = io.open(chadrc, "w")
  file:write(updated_content)
  file:close()
end

return M
