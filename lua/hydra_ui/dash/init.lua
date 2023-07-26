local M = {}
local api = vim.api
local fn = vim.fn

M.opts = {
  -- load_on_startup = true,

  header = {
    "   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣭⣿⣶⣿⣦⣼⣆         ",
    "    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ",
    "          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷⠄⠄⠄⠄⠻⠿⢿⣿⣧⣄     ",
    "           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ",
    "          ⢠⣿⣿⣿⠈  ⠡⠌⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ",
    "   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘⠄ ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ",
    "  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ",
    " ⣠⣿⠿⠛⠄⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ",
    " ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇⠄⠛⠻⢷⣄ ",
    "      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ",
    "       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ",
    "         ⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃       ",
  },

  buttons = {
    { "  Find File", "Spc f f", "Telescope find_files" },
    { "  Recent", "Spc f o", "Telescope oldfiles" },
    { "  New file", "Spc n f", "ene" },
    { "  Find Word", "Spc f w", "Telescope live_grep" },
    { "  Bookmarks", "Spc b m", "Telescope marks" },
    { "  Settings", "Spc t s", "ex $MYVIMRC | :HydraVimCloseEmptyBuffers" },
  },
}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  vim.api.nvim_create_user_command("HydraVimDash", function()
    if vim.g.dash_displayed then
      vim.cmd "bd"
    else
      require("hydra_ui.dash").open(vim.api.nvim_create_buf(false, true))
    end
  end, {})

  if vim.g.hydravim.ui.dash then
    vim.defer_fn(function()
      require("hydra_ui.dash").open()
    end, 0)
  end

  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if vim.bo.filetype == "dash" then
        vim.cmd "HydraVimDash"
      end
    end,
  })
end

M.build = function()
  if vim.g.hydravim.ui.dash then
    vim.cmd "HydraVimDash"
  end
end

local headerAscii = M.opts.header
local emmptyLine = string.rep(" ", vim.fn.strwidth(headerAscii[1]))

table.insert(headerAscii, 1, emmptyLine)
table.insert(headerAscii, 2, emmptyLine)

headerAscii[#headerAscii + 1] = emmptyLine
headerAscii[#headerAscii + 1] = emmptyLine

api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "dash" then
      vim.g.dash_displayed = false
    end
  end,
})

local dashWidth = #headerAscii[1] + 3

local max_height = #headerAscii + 4 + (2 * #M.opts.buttons) -- 4  = extra spaces i.e top/bottom
local get_win_height = api.nvim_win_get_height

M.open = function(buf)
  if (vim.api.nvim_buf_get_name(0) == "" and vim.bo.buflisted) or buf then
    buf = buf or api.nvim_create_buf(false, true)
    local win = nil

    -- close windows i.e splits
    for _, winnr in ipairs(api.nvim_list_wins()) do
      if win == nil and api.nvim_win_get_config(winnr).relative == "" then
        win = winnr
        api.nvim_win_set_buf(win, buf)
      end
      local bufnr = api.nvim_win_get_buf(winnr)
      if api.nvim_buf_is_valid(bufnr) and win ~= winnr then
        api.nvim_win_close(winnr, api.nvim_win_get_config(winnr).relative == "")
      end
    end

    vim.opt_local.filetype = "dash"
    vim.g.dash_displayed = true

    local header = headerAscii
    local buttons = M.opts.buttons

    local function addSpacing_toBtns(txt1, txt2)
      local btn_len = fn.strwidth(txt1) + fn.strwidth(txt2)
      local spacing = fn.strwidth(header[1]) - btn_len
      return txt1 .. string.rep(" ", spacing - 1) .. txt2 .. " "
    end

    local function addPadding_toHeader(str)
      local pad = (api.nvim_win_get_width(win) - fn.strwidth(str)) / 2
      return string.rep(" ", math.floor(pad)) .. str .. " "
    end

    local dashboard = {}

    for _, val in ipairs(header) do
      table.insert(dashboard, val .. " ")
    end

    for _, val in ipairs(buttons) do
      table.insert(dashboard, addSpacing_toBtns(val[1], val[2]) .. " ")
      table.insert(dashboard, header[1] .. " ")
    end

    local result = {}

    -- make all lines available
    for i = 1, math.max(get_win_height(win), max_height) do
      result[i] = ""
    end

    local headerStart_Index = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) + 1 -- 1 = To handle zero case
    local abc = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) + 1 -- 1 = To handle zero case

    -- set ascii
    for _, val in ipairs(dashboard) do
      result[headerStart_Index] = addPadding_toHeader(val)
      headerStart_Index = headerStart_Index + 1
    end

    api.nvim_buf_set_lines(buf, 0, -1, false, result)

    local dash = api.nvim_create_namespace "dash"
    local horiz_pad_index = math.floor((api.nvim_win_get_width(win) / 2) - (dashWidth / 2)) - 2

    for i = abc, abc + #header do
      api.nvim_buf_add_highlight(buf, dash, "DashAscii", i, horiz_pad_index, -1)
    end

    for i = abc + #header - 2, abc + #dashboard do
      api.nvim_buf_add_highlight(buf, dash, "DashButtons", i, horiz_pad_index, -1)
    end

    api.nvim_win_set_cursor(win, { abc + #header, math.floor(vim.o.columns / 2) - 13 })

    local first_btn_line = abc + #header + 2
    local keybind_lineNrs = {}

    for _, _ in ipairs(M.opts.buttons) do
      table.insert(keybind_lineNrs, first_btn_line - 2)
      first_btn_line = first_btn_line + 2
    end

    vim.keymap.set("n", "h", "", { buffer = true })
    vim.keymap.set("n", "<Left>", "", { buffer = true })
    vim.keymap.set("n", "l", "", { buffer = true })
    vim.keymap.set("n", "<Right>", "", { buffer = true })
    vim.keymap.set("n", "<Up>", "", { buffer = true })
    vim.keymap.set("n", "<Down>", "", { buffer = true })

    local function move_cursor(direction)
      local cur = fn.line "."
      local target_line

      if direction == "up" then
        target_line = cur == keybind_lineNrs[1] and keybind_lineNrs[#keybind_lineNrs] or cur - 2
      elseif direction == "down" then
        target_line = cur == keybind_lineNrs[#keybind_lineNrs] and keybind_lineNrs[1] or cur + 2
      end

      api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
    end

    vim.keymap.set("n", "<Up>", function()
      move_cursor "up"
    end, { buffer = true })

    vim.keymap.set("n", "<Down>", function()
      move_cursor "down"
    end, { buffer = true })

    vim.keymap.set("n", "k", function()
      move_cursor "up"
    end, { buffer = true })

    vim.keymap.set("n", "j", function()
      move_cursor "down"
    end, { buffer = true })

    -- pressing enter on
    vim.keymap.set("n", "<CR>", function()
      for i, val in ipairs(keybind_lineNrs) do
        if val == fn.line "." then
          local action = M.opts.buttons[i][3]

          if type(action) == "string" then
            vim.cmd(action)
          elseif type(action) == "function" then
            action()
          end
        end
      end
    end, { buffer = true })

    -- buf only options
    vim.opt_local.buflisted = false
    vim.opt_local.modifiable = false
    vim.opt_local.number = false
    vim.opt_local.list = false
    vim.opt_local.relativenumber = false
    vim.opt_local.wrap = false
    vim.opt_local.cul = false
  end
end

return M
