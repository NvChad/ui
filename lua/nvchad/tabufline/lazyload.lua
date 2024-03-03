local opts = require("nvconfig").ui.tabufline
local api = vim.api
local utils = require "nvchad.tabufline.utils"
local buf_opt = api.nvim_buf_get_option

local listed_bufs = {}

for _, nr in ipairs(vim.api.nvim_list_bufs()) do
  if buf_opt(nr, "buflisted") then
    table.insert(listed_bufs, utils.buf_info(nr))
  end
end

vim.t.bufs = listed_bufs

-- autocmds for tabufline -> track bufs on bufadd, bufenter events
-- thx to https://github.com/ii14 for helping me with tab-local variables
vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter", "tabnew" }, {
  callback = function(args)
    local bufs = vim.t.bufs

    if args.event == "BufAdd" and buf_opt(args.buf, "buflisted") then
      table.insert(bufs, utils.buf_info(args.buf))
    end

    vim.t.bufs = bufs
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local bufs = vim.t[tab].bufs
      if bufs then
        for i, bufnr in ipairs(bufs) do
          if bufnr == args.buf then
            table.remove(bufs, i)
            vim.t[tab].bufs = bufs
            break
          end
        end
      end
    end
  end,
})

if opts.lazyload then
  vim.api.nvim_create_autocmd({ "BufNew", "BufNewFile", "BufRead", "TabEnter", "TermOpen" }, {
    pattern = "*",
    group = vim.api.nvim_create_augroup("TabuflineLazyLoad", {}),
    callback = function()
      if #vim.fn.getbufinfo { buflisted = 1 } >= 2 or #vim.api.nvim_list_tabpages() >= 2 then
        vim.opt.showtabline = 2
        vim.opt.tabline = "%!v:lua.require('nvchad.tabufline.modules')()"
        vim.api.nvim_del_augroup_by_name "TabuflineLazyLoad"
      end
    end,
  })
else
  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('nvchad.tabufline.modules')()"
end
