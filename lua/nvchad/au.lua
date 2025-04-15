local autocmd = vim.api.nvim_create_autocmd
local config = require "nvconfig"

-- load nvdash only on empty file
if config.nvdash.load_on_startup then
  local opening_file = vim.fn.expand "%:p"
  local is_dir = vim.fn.isdirectory(opening_file) == 1

  if is_dir or opening_file == "" then
    local current_buffer = vim.api.nvim_get_current_buf()
    require("nvchad.nvdash").open()
    vim.api.nvim_buf_delete(current_buffer, { force = true, unload = false })
  end
end

if config.lsp.signature then
  autocmd("LspAttach", {
    callback = function(args)
      vim.schedule(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client then
          local signatureProvider = client.server_capabilities.signatureHelpProvider
          if signatureProvider and signatureProvider.triggerCharacters then
            require("nvchad.lsp.signature").setup(client, args.buf)
          end
        end
      end)
    end,
  })
end

-- reload the plugin!
autocmd("BufWritePost", {
  pattern = vim.tbl_map(function(path)
    return vim.fs.normalize(vim.uv.fs_realpath(path))
  end, vim.fn.glob(vim.fn.stdpath "config" .. "/lua/**/*.lua", true, true, true)),
  group = vim.api.nvim_create_augroup("ReloadNvChad", {}),

  callback = function(opts)
    local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
    local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
    local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")

    require("nvchad.utils").reload(module)
    -- vim.cmd("redraw!")
  end,
})

vim.api.nvim_create_user_command("MasonInstallAll", function()
  require("nvchad.mason").install_all()
end, {})

if config.colorify.enabled then
  require("nvchad.colorify").run()
end

local dir = vim.fn.stdpath "data" .. "/nvnotify"

if not vim.uv.fs_stat(dir) then
  vim.fn.mkdir(dir, "p")
  require "nvchad.winmes" {
    { "* NvChad UI v3.0 has been released! Check https://nvchad.com/news/nvui", "added" },
    { "* Docs have been added at :h nvui, don't forget to read them!" },
    { "* Check the Volt plugin showcase at https://nvchad.com/news/volt" },
  }
end
