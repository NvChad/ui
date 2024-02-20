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
      ...
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

You can also call a function here to dynamically generate the status line text.
```lua
    overriden_modules = function(modules)
      modules[2] = (function()
            local some_dynamic_value = "hello world"
            return some_dynamic_value
      end)()
    end,
```

# Credits

- Huge thanks to [@lucario387](https://github.com/lucario387) for creating `nvchad_types`.
