local M = {}
local fn = vim.fn
local opt_local = vim.api.nvim_set_option_value
local base46_path = vim.fn.fnamemodify(debug.getinfo(require("base46").merge_tb, "S").source:sub(2), ":p:h")

M.list_themes = function()
  local default_themes = vim.fn.readdir(base46_path .. '/themes')
  local custom_themes = vim.uv.fs_stat(fn.stdpath "config" .. "/lua/themes")

  if custom_themes and custom_themes.type == "directory" then
    local themes_tb = fn.readdir(fn.stdpath "config" .. "/lua/themes")
    for _, value in ipairs(themes_tb) do
      table.insert(default_themes, value)
    end
  end

  for index, theme in ipairs(default_themes) do
    default_themes[index] = theme:match "(.+)%..+"
  end

  return default_themes
end

M.replace_word = function(old, new, filepath)
  filepath = filepath or vim.fn.stdpath "config" .. "/lua/" .. "chadrc.lua"

  local file = io.open(filepath, "r")
  if file then
    local added_pattern = string.gsub(old, "-", "%%-") -- add % before - if exists
    local new_content = file:read("*all"):gsub(added_pattern, new)

    file = io.open(filepath, "w")
    file:write(new_content)
    file:close()
  end
end

M.set_cleanbuf_opts = function(ft, buf)
  opt_local("buflisted", false, { buf = buf })
  opt_local("modifiable", false, { buf = buf })
  opt_local("buftype", "nofile", { buf = buf })
  opt_local("number", false, { scope = "local" })
  opt_local("list", false, { scope = "local" })
  opt_local("wrap", false, { scope = "local" })
  opt_local("relativenumber", false, { scope = "local" })
  opt_local("cursorline", false, { scope = "local" })
  opt_local("colorcolumn", "0", { scope = "local" })
  opt_local("foldcolumn", "0", { scope = "local" })
  opt_local("ft", ft, { buf = buf })
  vim.g[ft .. "_displayed"] = true
end

M.reload = function(module)
  require("plenary.reload").reload_module "nvconfig"
  require("plenary.reload").reload_module "chadrc"
  require("plenary.reload").reload_module "base46"
  require("plenary.reload").reload_module "nvchad"

  if module then
    require("plenary.reload").reload_module(module)
  end

  require "nvchad"
  require("base46").load_all_highlights()
end

return M
