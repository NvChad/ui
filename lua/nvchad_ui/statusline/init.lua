return {
  run = function(config)
    vim.g.statusline_sep_style = config.separator_style

    local modules = require "nvchad_ui.statusline.modules"

    if config.overriden_modules then
      modules = vim.tbl_deep_extend("force", modules, config.overriden_modules())
    end

    defaults = {
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

    -- Pass in all the modules, and let users decide their order
    if config.overriden_table then
      defaults = config.overriden_table(modules)
    end

    return table.concat(defaults)
  end,
}
