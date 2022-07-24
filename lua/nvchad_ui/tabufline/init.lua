return {
  run = function(opts)
    local modules = require "nvchad_ui.tabufline.modules"

    -- merge user modules :D
    if opts.overriden_modules then
      modules = vim.tbl_deep_extend("force", modules, opts.overriden_modules())
    end

    local result = modules.bufferlist() .. (modules.tablist() or "") .. modules.buttons()
    return (vim.g.nvimtree_side == "left") and modules.CoverNvimTree() .. result or result .. modules.CoverNvimTree()
  end,
}
