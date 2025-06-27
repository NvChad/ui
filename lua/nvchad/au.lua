local autocmd = vim.api.nvim_create_autocmd
local config = require "nvconfig"

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

local dir = vim.fn.stdpath "data" .. "/nvnotify1"

if not vim.uv.fs_stat(dir) then
  vim.fn.mkdir(dir, "p")
  require "nvchad.winmes" {
    { "* Blink.cmp plugin integration has been added, will be tested for 2 months" },
    { " " },
    { '* { import = "nvchad.blink.lazyspec" } in your plugins file' },
    { " " },
    { "* Discuss at https://github.com/NvChad/NvChad/discussions/3244" },
  }
end
