local opts = require("core.utils").load_config().ui.tabufline

-- store listed buffers in tab local var
vim.t.bufs = vim.api.nvim_list_bufs()

local listed_bufs = {}

for _, val in ipairs(vim.t.bufs) do
  if vim.bo[val].buflisted then
    table.insert(listed_bufs, val)
  end
end

vim.t.bufs = listed_bufs

-- autocmds for tabufline -> store bufnrs on bufadd, bufenter events
-- thx to https://github.com/ii14 & stores buffer per tab -> table
vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter", "tabnew" }, {
  callback = function(args)
    local bufs = vim.t.bufs

    if vim.t.bufs == nil then
      vim.t.bufs = vim.api.nvim_get_current_buf() == args.buf and {} or { args.buf }
    else
      -- check for duplicates
      if
        not vim.tbl_contains(bufs, args.buf)
        and (args.event == "BufEnter" or vim.bo[args.buf].buflisted or args.buf ~= vim.api.nvim_get_current_buf())
        and vim.api.nvim_buf_is_valid(args.buf)
        and vim.bo[args.buf].buflisted
      then
        table.insert(bufs, args.buf)

        -- remove unnamed buffer which isnt current buf & modified
        for index, bufnr in ipairs(bufs) do
          if
            #vim.api.nvim_buf_get_name(bufnr) == 0
            and (vim.api.nvim_get_current_buf() ~= bufnr or bufs[index + 1])
            and not vim.api.nvim_buf_get_option(bufnr, "modified")
          then
            table.remove(bufs, index)
          end
        end

        vim.t.bufs = bufs
      end
    end
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

require("core.utils").load_mappings "tabufline"

if opts.lazyload then
  vim.api.nvim_create_autocmd({ "BufNew", "BufNewFile", "BufRead", "TabEnter", "TermOpen" }, {
    pattern = "*",
    group = vim.api.nvim_create_augroup("TabuflineLazyLoad", {}),
    callback = function()
      if #vim.fn.getbufinfo { buflisted = 1 } >= 2 or #vim.api.nvim_list_tabpages() >= 2 then
        vim.opt.showtabline = 2
        vim.opt.tabline = "%!v:lua.require('nvchad_ui.tabufline.modules').run()"
        vim.api.nvim_del_augroup_by_name "TabuflineLazyLoad"
      end
    end,
  })
else
  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('nvchad_ui.tabufline.modules').run()"
end
