return function(opts)
  if not opts.enabled then
    return
  end

  require("core.utils").load_mappings "tabufline"

  if opts.lazyload then
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter" }, {
      pattern = "*",
      group = vim.api.nvim_create_augroup("TabuflineLazyLoad", {}),
      callback = function()
        if #vim.fn.getbufinfo { buflisted = 1 } >= 2 then
          vim.opt.showtabline = 2
          vim.opt.tabline = "%!v:lua.require('nvchad_ui').tabufline()"
          vim.api.nvim_del_augroup_by_name "TabuflineLazyLoad"
        end
      end,
    })
  else
    vim.opt.showtabline = 2
    vim.opt.tabline = "%!v:lua.require('nvchad_ui').tabufline()"
  end
end
