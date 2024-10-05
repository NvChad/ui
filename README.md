# NvChad UI Plugin 

This ui plugin is a collection of many UI modules like statusline, tabline, cheatsheet, nvdash and much more!
- Docs at `:h nvui` 

## Install

- Create `lua/chadrc.lua` file that returns a table, can be empty table too.
- Table structure must be same as [nvconfig.lua](https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua)

In your plugins file
```lua
 "nvim-lua/plenary.nvim",

 {
   "nvchad/ui",
    config = function()
      require "nvchad" 
    end
 },

 {
    "nvchad/base46",
    lazy = true,
    build = function()
      require("base46").load_all_highlights()
    end,
 },
```

Base46 setup
```lua
 -- put this in your main init.lua file ( before lazy setup )
 vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

-- put this after lazy setup 

-- (method 1, For heavy lazyloaders)
 dofile(vim.g.base46_cache .. "defaults")
 dofile(vim.g.base46_cache .. "statusline")

-- (method 2, for non lazyloaders) to load all highlights at once
 for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
   dofile(vim.g.base46_cache .. v)
 end
```

## List of Features with screenshots 

## Tabufline

- Mix of tabline & bufferline. 
- Each tab will have its own set of buffers stored, and the tabufline will show those only.
- Think of it like workspaces on Linux/Windows where windows stay in their own workspaces, but in vim buffers from all tabs will be shown in every tab!

[NvChad - Maintain buffers per tab!  ( tabufline )  ｜ Neovim [V_9iJ96U_k8].webm](https://github.com/user-attachments/assets/ff3026f3-7943-4f71-9cba-373035d9b4c5)

## Statusline 

- Statusline with 4 different styles

![nvchad statusline](https://nvchad.com/features/statuslines.webp)

## Term 

- Create, toggle terminals with cmd, window options ( can also be used to color each term window differently! )
- Manage code runner 
- ( :Telescope terms ) to unhide [terminal buffers](https://www.youtube.com/embed/3DysWI_6YpQ) <kbd> leader + pt </kbd>.

## Lsp Signature

- Minimal signature window ( [50 LOC ~](https://github.com/NvChad/ui/blob/v3.0/lua/nvchad/lsp/signature.lua)), just uses `vim.lsp.buf.signature_help` on some autocmds.

![image](https://github.com/user-attachments/assets/b2db5cd1-a81b-41a7-a132-7d2dc15edf39)

## Lsp Variable Renamer

- Used for renaming

![image](https://github.com/user-attachments/assets/c90c1de4-3f42-4bc4-9392-766ca989e4ea)

## Colorify

- Minimal colorizer module that colors hex colors and all LSP related variables etc ( useful for tailwind, css etc and every lsp that supports it )
- Just supports virtual text, fg, bg

![image](https://github.com/user-attachments/assets/b8ac8c83-f440-4513-b283-ace1aa99eb92)
![image](https://github.com/user-attachments/assets/49d88e64-e185-4992-adde-c5e815a53975)
![image](https://github.com/user-attachments/assets/d80bb30a-f18f-44a5-8034-78a3bd2c2c17)

## Nvdash

- 150 ~ LOC Dashboard module, minimal & nothing fancy!
 
![nvdash](https://github.com/user-attachments/assets/072c8733-8a44-4cf3-8732-e5fa7eb9459e)

## Cmp styles

- A lot of cmp theming with base46!
- Do know that nvchad's base46 has like 68 themes, so dont judge the screenshots by colors!
- Support for Tailwind & Css LSP colors

![image](https://github.com/user-attachments/assets/661bbc0f-7073-4b4c-81cb-7cf035e29d6f)
![image](https://github.com/user-attachments/assets/0557e479-2735-4a86-b23a-eafa540ab4a5)
![image](https://github.com/user-attachments/assets/5b445b45-4802-4851-a8a4-1de051d58ade)
![image](https://github.com/user-attachments/assets/3fdbbaa7-a212-499a-a291-0609c72b6f96)
![image](https://github.com/user-attachments/assets/28775c0c-ce85-45cd-8c76-bdd97344f5b4)
![image](https://github.com/user-attachments/assets/c44e405b-f0f1-4c56-ae58-85c49b9616a0)
![image](https://github.com/user-attachments/assets/57e88886-7c95-4e77-a252-2021160cd274)

## Modern Theme Picker

- With 3 different styles : bordered, compact, flat

![image](https://github.com/user-attachments/assets/897e46f1-9ae2-4cc2-8fa2-64eff40a90dd)

## NvCheatsheet

- Auto-generated mappings cheatsheet module, which has a similar layout to that of CSS's masonry layout.
- It has 2 themes ( grid & simple )
![img](https://nvchad.com/features/nvcheatsheet.webp)

## Colorify

- Colors hex color on buffer and lsp colors on the buffer, like tailwind etc

![image](https://github.com/user-attachments/assets/c5f3dc55-7810-48ae-879e-25453ab16b71)

## Automatic Mason install 

- MasonInstallAll command will now capture all the mason tools from your config
- Supported plugins are : lspconfig, nvim-lint, conform.nvim
- So for example if you have lspconfig like this :

```lua 
require("lspconfig").html.setup{}
require("lspconfig").clangd.setup{}
``` 
<br/>

Then running MasonInstallAll will install both the mason pkgs 

check `:h nvui.mason` for more info

# Credits

- Huge thanks to [@lucario387](https://github.com/lucario387) for creating `nvchad_types`.
