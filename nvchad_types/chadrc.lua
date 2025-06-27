---@meta

---@class ChadrcConfig
---@field ui? UIConfig
---@field base46? Base46Config

---@field cheatsheet? NvCheatsheetConfig


---@class Base46Config
--- List of highlights group to add.
--- Should be highlights that is not a part of base46 default integrations
--- (The default is all hlgroup that can be found from `hl_override`)
--- Example
--- ```lua
---     hl_add = {
---       ["HLName"] = {fg = "red"},
---     }
--- ```
--- see https://github.com/NvChad/base46/tree/master/lua/base46/integrations
---@field hl_add? HLTable
--- List of highlight groups that is part of base46 default integration that you want to change
--- ```lua
---     hl_override = {
---       ["HLName"] = {fg = "red"},
---     }
--- ```
--- see https://github.com/NvChad/base46/tree/master/lua/base46/integrations
---@field hl_override? Base46HLGroupsList
--- see https://github.com/NvChad/base46/tree/master/lua/base46/themes for the colors of each theme
--- Also accept a special key `all` to change a base46 key to a specific color for all themes
---@field changed_themes? ChangedTheme
--- A table with 2 strings, denoting the themes to toggle between.
--- One of the 2 strings must be the value of `theme` field
--- Example:
--- ```lua
---     theme_toggle = { "onedark", "one_light", },
--- ```
---@field theme_toggle? ThemeName[]
--- Enable transparency or not
---@field transparency? boolean
--- Theme to use.
--- You can try out the theme by executing `:Telescope themes`
--- see https://github.com/NvChad/base46/tree/master/lua/base46/themes
---@field theme? ThemeName
---@field integrations? Base46Integrations[]

--- UI related configuration
--- e.g. statusline, cmp themes, dashboard
---@class UIConfig

---@field telescope? NvTelescopeConfig

--- Whether to enable LSP Semantic Tokens highlighting
--- List of extras themes for other plugins not in NvChad that you want to compile



---@class NvTelescopeConfig
--- Telescope style
---@field style? '"borderless"'|'"bordered"'


---@class NvCheatsheetConfig
--- Cheatsheet theme
---@field theme? '"grid"'|'"simple"'
---@field excluded_groups? string[]

