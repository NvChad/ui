local api = vim.api
local opt_local = vim.opt_local

-- Show nice list of notes after nvchad installation
local function screen()
  local text_on_screen = {
    "",
    "",
    "███╗   ██╗   ██████╗  ████████╗ ███████╗ ███████╗",
    "████╗  ██║  ██╔═══██╗ ╚══██╔══╝ ██╔════╝ ██╔════╝",
    "██╔██╗ ██║  ██║   ██║    ██║    █████╗   ███████╗",
    "██║╚██╗██║  ██║   ██║    ██║    ██╔══╝   ╚════██║",
    "██║ ╚████║  ╚██████╔╝    ██║    ███████╗ ███████║",
    "",
    "",
    "  Please read the docs at nvchad.com from start to end 󰕹 󰱬",
    "",
    "  All NvChad available options are in 'core/default_config.lua', Know them",
    "",
    "  Mason just downloads binaries, dont expect it to configure lsp automatically",
    "",
    "  Dont edit files outside custom folder or you lose NvChad updates forever 󰚌",
    "",
    "  Ask NvChad issues in nvchad communities only, go to https://nvchad.com/#community",
    "",
    "  Read the plugin docs to utilize 100% of their functionality.",
    "",
    "  If you dont see any syntax highlighting not working, install a tsparser for it",
    "",
    "  Check the default mappings by pressing space + ch or NvCheatsheet command",
    "",
    "Now quit nvim!",
  }

  local buf = api.nvim_create_buf(false, true)

  vim.opt_local.filetype = "nvchad_postbootstrap_window"
  api.nvim_buf_set_lines(buf, 0, -1, false, text_on_screen)

  local nvpostscreen = api.nvim_create_namespace "nvpostscreen"

  for i = 1, #text_on_screen do
    api.nvim_buf_add_highlight(buf, nvpostscreen, "LazyCommit", i, 0, -1)
  end

  api.nvim_win_set_buf(0, buf)

  -- buf only options
  opt_local.buflisted = false
  opt_local.modifiable = false
  opt_local.number = false
  opt_local.list = false
  opt_local.relativenumber = false
  opt_local.wrap = false
  opt_local.cul = false
end

-- install mason pkgs & show notes on screen after it
return function()
  api.nvim_buf_delete(0, { force = true }) -- close previously opened lazy window

  vim.schedule(function()
    vim.cmd "MasonInstallAll"

    -- Keep track of which mason pkgs get installed
    local packages = table.concat(vim.g.mason_binaries_list, " ")

    require("mason-registry"):on("package:install:success", function(pkg)
      packages = string.gsub(packages, pkg.name:gsub("%-", "%%-"), "") -- rm package name

      -- run above screen func after all pkgs are installed.
      if packages:match "%S" == nil then
        vim.schedule(function()
          api.nvim_buf_delete(0, { force = true })
          vim.cmd "echo '' | redraw" -- clear cmdline
          screen()
        end)
      end
    end)
  end)
end
