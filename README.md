# NvChad's UI plugin
Lightweight &amp; performant ui plugin for nvchad providing the following : 
- Statusline with 4 themes 
- Tabufline ( manages buffers per tab ) 
- NvDash ( dashboard ) 
- NvCheatsheet ( auto-generates cheatsheet based on default & user mappings in nice grid (Masonry layout) / column layout )
- basic Lsp signature 
- Lsp renamer window

# Default config 

- Refer [NvChad docs](https://nvchad.com/docs/config/nvchad_ui) for detailed info
- Or check the `core/default_config.lua` file in your nvchad config for quick info.

# Overriding Status Line
The config for the status line is in `.config/nvim/lua/core/default_config.lua`

here you will find a line that looks like this:
```lua
  statusline = {
    theme = "default", -- default/vscode/vscode_colored/minimal
    -- default/round/block/arrow separators work only for default statusline theme
    -- round and block will work for minimal theme only
    separator_style = "default",
    overriden_modules = nil,
  },
```

You can change the status line by passing a function to overridden_modules. This function will take a parameter of modules, you can overwrite the module by overriding the index. For example to overrite the file name module you can do the following:
```lua
  statusline = {
    theme = "default", -- default/vscode/vscode_colored/minimal
    -- default/round/block/arrow separators work only for default statusline theme
    -- round and block will work for minimal theme only
    separator_style = "default",
    overriden_modules = function(modules)
          modules[2] = 'hello world'
    end
  },
```

Here is a full example that creates a variable named vim.g.file_path_length which allows you to make your file path in the status line as short or as long as you want.
```lua
    overriden_modules = function(modules)
      local function stbufnr()
        return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
      end

      local function get_file_path(chosen_length)
        local adjusted_length = chosen_length - 1
        local parts_to_get = adjusted_length <= 0 and 0 or adjusted_length
        local path = vim.api.nvim_buf_get_name(stbufnr())
        local parts = {}

        if path ~= "" then
          -- Split the path into parts
          for part in path:gmatch("[^/]+") do
            table.insert(parts, part)
          end


          -- Get all parts
          local num_parts = #parts
          for i = 1, num_parts do
            table.insert(parts, parts[i]) -- Corrected the variable name here
          end
        end

        local output = {}
        for i = #parts - parts_to_get, #parts do
          table.insert(output, parts[i])
        end

        local ret_value = table.concat(output, "/")
        return ret_value
      end

      modules[2] = (function()
        local config = require("core.utils").load_config().ui.statusline
        local sep_style = config.separator_style
        local default_sep_icons = {
          default = { left = "", right = "" },
          round = { left = "", right = "" },
          block = { left = "█", right = "█" },
          arrow = { left = "", right = "" },
        }
        local separators = (type(sep_style) == "table" and sep_style) or default_sep_icons[sep_style]
        local sep_r = separators["right"]
        local icon = " 󰈚 "

        local parts_to_get = vim and vim.g and vim.g.file_path_length or 1
        local fragments = get_file_path(parts_to_get)
        local name = ""

        if #fragments > 0 then
          name = fragments
        else
          name = "Empty "
        end


        if name ~= "Empty " then
          local devicons_present, devicons = pcall(require, "nvim-web-devicons")

          if devicons_present then
            local ft_icon = devicons.get_icon(name)
            icon = (ft_icon ~= nil and " " .. ft_icon) or icon
          end

          name = " " .. name .. " "
        end

        return "%#St_file_info#" .. icon .. name .. "%#St_file_sep#" .. sep_r
      end)()
    end,
```

# Credits

- Huge thanks to [@lucario387](https://github.com/lucario387) for creating `nvchad_types`.
