local M = {}
local fn = vim.fn

M.list_themes = function()
  local default_themes = vim.fn.readdir(vim.fn.stdpath "data" .. "/lazy/base46/lua/base46/themes")

  local custom_themes = vim.loop.fs_stat(fn.stdpath "config" .. "/lua/custom/themes")

  if custom_themes and custom_themes.type == "directory" then
    local themes_tb = fn.readdir(fn.stdpath "config" .. "/lua/custom/themes")
    for _, value in ipairs(themes_tb) do
      default_themes[#default_themes + 1] = value
    end
  end

  for index, theme in ipairs(default_themes) do
    default_themes[index] = theme:match "(.+)%..+"
  end

  return default_themes
end

M.replace_word = function(old, new)
  local chadrc = vim.fn.stdpath "config" .. "/lua/custom/" .. "chadrc.lua"
  local file = io.open(chadrc, "r")
  local added_pattern = string.gsub(old, "-", "%%-") -- add % before - if exists
  local new_content = file:read("*all"):gsub(added_pattern, new)

  file = io.open(chadrc, "w")
  file:write(new_content)
  file:close()
end

M.get_message = function()
  local done = false
  for _, client in ipairs(vim.lsp.get_clients()) do
    for progress in client.progress do
      local value = progress.value
      if type(value) == "table" and value.kind then
        if value.kind == "end" then
          done = true
        end
        return {
          msg = value.message,
          title = value.title,
          percentage = value.percentage,
          done = done,
        }
      end
    end
  end
  return nil
end
return M
