local M = {}
local api = vim.api
local fn = vim.fn

dofile(vim.g.base46_cache .. "nvdash")

local config = require("core.utils").load_config().ui.nvdash

local headerAscii = config.header
local emmptyLine = string.rep(" ", vim.fn.strwidth(headerAscii[1]))

table.insert(headerAscii, 1, emmptyLine)
table.insert(headerAscii, 2, emmptyLine)

headerAscii[#headerAscii + 1] = emmptyLine
headerAscii[#headerAscii + 1] = emmptyLine

api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "nvdash" then
      vim.g.nvdash_displayed = false
    end
  end,
})

local nvdashWidth = #headerAscii[1] + 3

local max_height = #headerAscii + 4 + (2 * #config.buttons) -- 4  = extra spaces i.e top/bottom
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

    vim.opt_local.filetype = "nvdash"
    vim.g.nvdash_displayed = true

    local header = headerAscii
    local buttons = config.buttons

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

    local nvdash = api.nvim_create_namespace "nvdash"
    local horiz_pad_index = math.floor((api.nvim_win_get_width(win) / 2) - (nvdashWidth / 2)) - 2

    for i = abc, abc + #header do
      api.nvim_buf_add_highlight(buf, nvdash, "NvDashAscii", i, horiz_pad_index, -1)
    end

    for i = abc + #header - 2, abc + #dashboard do
      api.nvim_buf_add_highlight(buf, nvdash, "NvDashButtons", i, horiz_pad_index, -1)
    end

    api.nvim_win_set_cursor(win, { abc + #header, math.floor(vim.o.columns / 2) - 13 })

    local first_btn_line = abc + #header + 2
    local keybind_lineNrs = {}

    for _, _ in ipairs(config.buttons) do
      table.insert(keybind_lineNrs, first_btn_line - 2)
      first_btn_line = first_btn_line + 2
    end

    vim.keymap.set("n", "h", "", { buffer = true })
    vim.keymap.set("n", "<Left>", "", { buffer = true })
    vim.keymap.set("n", "l", "", { buffer = true })
    vim.keymap.set("n", "<Right>", "", { buffer = true })
    vim.keymap.set("n", "<Up>", "", { buffer = true })
    vim.keymap.set("n", "<Down>", "", { buffer = true })

    vim.keymap.set("n", "k", function()
      local cur = fn.line "."
      local target_line = cur == keybind_lineNrs[1] and keybind_lineNrs[#keybind_lineNrs] or cur - 2
      api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
    end, { buffer = true })

    vim.keymap.set("n", "j", function()
      local cur = fn.line "."
      local target_line = cur == keybind_lineNrs[#keybind_lineNrs] and keybind_lineNrs[1] or cur + 2
      api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
    end, { buffer = true })

    -- pressing enter on
    vim.keymap.set("n", "<CR>", function()
      for i, val in ipairs(keybind_lineNrs) do
        if val == fn.line "." then
          local action = config.buttons[i][3]

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
