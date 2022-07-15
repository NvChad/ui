return function(opts)
   if opts.enabled and opts.lazyload then
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter" }, {
         pattern = "*",
         group = vim.api.nvim_create_augroup("TabuflineLazyLoad", {}),
         callback = function()
            if #vim.fn.getbufinfo { buflisted = 1 } >= 2 then
               vim.opt.showtabline = 2
               vim.api.nvim_del_augroup_by_name "TabuflineLazyLoad"
            end
         end,
      })
   elseif opts.enabled then
      vim.opt.showtabline = 2
   end
end
