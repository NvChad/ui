local M = {}
local masonames = require "nvchad.mason.names"

local get_pkgs = function(data)
  local tools = data or {}

  local lsps = require("lspconfig.util").available_servers()
  tools = vim.list_extend(tools, lsps)

  local conform_exists, conform = pcall(require, "conform")

  if conform_exists then
    local formatters = conform.list_all_formatters()

    local formatters_names = vim.tbl_map(function(formatter)
      return formatter.name
    end, formatters)

    tools = vim.list_extend(tools, formatters_names)
  end

  local lint_exists, lint = pcall(require, "lint")

  if lint_exists then
    local linters = lint.linters_by_ft

    for _, v in pairs(linters) do
      table.insert(tools, v[1])
    end
  end

  -- rm duplicates
  local pkgs = {}

  for _, v in pairs(tools) do
    if not (vim.tbl_contains(pkgs, masonames[v])) then
      table.insert(pkgs, masonames[v])
    end
  end

  return pkgs
end

M.install_all = function(data)
  vim.cmd "Mason"

  local mr = require "mason-registry"

  mr.refresh(function()
    for _, tool in ipairs(get_pkgs(data)) do
      local p = mr.get_package(tool)

      if not p:is_installed() then
        p:install()
      end
    end
  end)
end

return M
