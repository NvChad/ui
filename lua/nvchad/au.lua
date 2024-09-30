local autocmd = vim.api.nvim_create_autocmd
local config = require "nvconfig"

if vim.version().minor >= 10 then
  autocmd("LspProgress", {
    callback = function(args)
      if string.find(args.match, "end") then
        vim.cmd "redrawstatus"
      end
      vim.cmd "redrawstatus"
    end,
  })
end

if config.lsp.signature then
  autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client then
        local signatureProvider = client.server_capabilities.signatureHelpProvider
        if signatureProvider and signatureProvider.triggerCharacters then
          require("nvchad.lsp.signature").setup(client, args.buf)
        end
      end
    end,
  })
end

-- redraw dashboard/cheatsheet
autocmd("VimResized", {
  callback = function()
    if vim.bo.ft == "nvdash" then
      vim.cmd "bw"
      require("nvchad.nvdash").open()
    elseif vim.bo.ft == "nvcheatsheet" then
      vim.cmd "bw"
      require("nvchad.cheatsheet." .. config.cheatsheet.theme)()
    end
  end,
})

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

if config.mason.cmd then
  vim.api.nvim_create_user_command("MasonInstallAll", function()
    require("nvchad.mason").install_all(config.mason.pkgs)
  end, {})
end
