local M = {}
local fn = vim.fn

M.list_themes = function()
  local default_themes = vim.fn.readdir(vim.fn.stdpath "data" .. "/lazy/base46/lua/base46/themes")
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

M.set_cleanbuf_opts = function(ft)
  local opt = vim.opt_local

  opt.buflisted = false
  opt.modifiable = false
  opt.buftype = "nofile"
  opt.number = false
  opt.list = false
  opt.wrap = false
  opt.relativenumber = false
  opt.cursorline = false
  opt.colorcolumn = "0"
  opt.foldcolumn = "0"

  vim.opt_local.filetype = ft
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
