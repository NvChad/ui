---@meta

---@class ApiKeymapOpts
---@field nowait? boolean If true, once the `lhs` is matched, the `rhs` will be executed
---@field expr? boolean Specify whether the `rhs` is an expression to be evaluated or not (default false)
---@field silent? boolean Specify whether `rhs` will be echoed on the command line
---@field unique? boolean Specify whether not to map if there exists a keymap with the same `lhs`
---@field script? boolean
---@field desc? string Description for what the mapping will do
---@field noremap? boolean Specify whether the `rhs` will execute user-defined keymaps if it matches some `lhs` or not
---@field replace_keycodes? boolean Only effective when `expr` is **true**, specify whether to replace keycodes in the resuling string
---@field callback function Lua function to call when the mapping is executed

---@alias VimKeymapMode
---|'"n"' # Normal Mode
---|'"x"' # Visual Mode Keymaps
---|'"s"' # Select Mode
---|'"v"' # Equivalent to "xs"
---|'"o"' # Operator-pending mode
---|'"i"' # Insert Mode
---|'"c"' # Command-Line Mode
---|'"l"' # Insert, Command-Line and Lang-Arg
---|'"t"' # Terminal Mode
---|'"!"' # Equivalent to Vim's `:map!`, which is equivalent to '"ic"'
---|'""'  # Equivalent to Vim's `:map`, which is equivalent to "nxso"

---@class NvKeymapOpts : ApiKeymapOpts
---@field remap? boolean inverse of `noremap`
---@field buffer? integer|boolean|nil Specify the buffer that the keymap will be effective in. If 0 or true, the current buffer will be used
