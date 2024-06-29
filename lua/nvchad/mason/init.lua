local M = {}
local conform_pkgs = require "nvchad.mason.pkgnames.conform"
local lsp_pkgs = require "nvchad.mason.pkgnames.lsp"

local get_pkgs = function(data)
  local lsps = require("lspconfig.util").available_servers()
  local formatters = require("conform").list_all_formatters()

  local pkgnames = data or {}

  -- conform formatters
  for _, v in ipairs(formatters) do
    local pkg = conform_pkgs[v.name]

    if pkg then
      table.insert(pkgnames, pkg)
    end
  end

  -- lspconfig lsps
  for _, v in ipairs(lsps) do
    if lsp_pkgs[v] then
      table.insert(pkgnames, lsp_pkgs[v])
    end
  end

  return pkgnames
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
