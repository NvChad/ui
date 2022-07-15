local statusline_opts = require("nvchad_ui").statusline

return {
   setup = function(opts)
      statusline_opts = vim.tbl_deep_extend("force", statusline_opts, opts.statusline or {})

      vim.g.statusline_sep_style = statusline_opts.separator_style

      local modules = require "nvchad_ui.statusline.modules"

      if statusline_opts.overriden_modules then
         modules = vim.tbl_deep_extend("force", modules, statusline_opts.overriden_modules())
      end

      return table.concat {
         modules.mode(),
         modules.fileInfo(),
         modules.git(),

         "%=",
         modules.LSP_progress(),
         "%=",

         modules.LSP_Diagnostics(),
         modules.LSP_status() or "",
         modules.cwd(),
         modules.cursor_position(),
      }
   end,
}
