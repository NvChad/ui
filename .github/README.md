# 🌊 HydraVim UI

This is the set of plugins for HydraVim Default config.

- This is a fork of NvChad UI.

## 💤 Lazy

```lua
{
  "HydraVim/hydra-ui",
  tag = "1.3",
  lazy = false,
  build = function()
    require("hydra_ui.dash").build()
  end,
  config = function()
    require("hydra_ui.dash").setup()
  end
}
```

## ⚙ Options

### Dash

```lua
{
  --- Header: Represents an ASCII art.
  -- @field header The header text in ASCII art.
  header = {
    " ------ ",
    " ------ "
    " ------ "
  },

  --- Buttons: Represents a set of buttons with labels, keyboard shortcuts, and commands.
  -- @field buttons An array of buttons, a button containing: `label`, `shortcut`, and `commands`.
  buttons = {
    { "  Find File", "Spc f f", "Telescope find_files" },
    { "  Recent", "Spc f o", "Telescope oldfiles" },
    { "  New file", "Spc n f", "ene" },
    { "  Find Word", "Spc f w", "Telescope live_grep" },
    { "  Bookmarks", "Spc b m", "Telescope marks" },
  },
}
```
