local M = {}

local config = require "nvchad_ui.config"
local headerAscii = config.nvdash.header
local emmptyLine = string.rep(" ", vim.fn.strwidth(headerAscii[1]))

table.insert(headerAscii, 1, emmptyLine)
table.insert(headerAscii, 2, emmptyLine)

headerAscii[#headerAscii + 1] = emmptyLine
headerAscii[#headerAscii + 1] = emmptyLine

M.open = function()
  -- load dashboard
  if vim.api.nvim_buf_get_name(0) == "" then
    local api = vim.api
    local fn = vim.fn
    local header = headerAscii
    local buttons = config.nvdash.buttons

    local function addSpacing_toBtns(txt1, txt2)
      local btn_len = fn.strwidth(txt1) + fn.strwidth(txt2)
      local spacing = fn.strwidth(header[1]) - btn_len
      return txt1 .. string.rep(" ", spacing - 1) .. txt2 .. " "
    end

    local function addPadding_toHeader(str)
      local pad = (api.nvim_win_get_width(0) - fn.strwidth(str)) / 2
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

    -- vim.cmd "enew"
    local result = {}
    local get_win_height = vim.api.nvim_win_get_height

    -- make all lines available
    for i = 1, get_win_height(0) do
      result[i] = ""
    end

    local headerStart_Index = math.floor((get_win_height(0) / 2) - (#dashboard / 2))
    local abc = math.floor((get_win_height(0) / 2) - (#dashboard / 2))

    -- set ascii
    for _, val in ipairs(dashboard) do
      result[headerStart_Index] = addPadding_toHeader(val)
      headerStart_Index = headerStart_Index + 1
    end

    api.nvim_buf_set_lines(0, 0, -1, false, result)

    local nvdash = vim.api.nvim_create_namespace "nvdash"
    local horiz_pad_index = math.floor((api.nvim_win_get_width(0) / 2) - (36 / 2)) - 2

    for i = abc, abc + #header - 2 do
      api.nvim_buf_add_highlight(0, nvdash, "NvDashAscii", i, horiz_pad_index, -1)
    end

    for i = abc + #header - 2, abc + #dashboard do
      api.nvim_buf_add_highlight(0, nvdash, "NvDashButtons", i, horiz_pad_index, -1)
    end

    vim.api.nvim_win_set_cursor(0, { abc + #header + 2, math.floor(vim.o.columns / 2) - 13 })

    local first_btn_line = abc + #header + 2
    local keybind_lineNrs = {}

    for _, _ in ipairs(config.nvdash.buttons) do
      table.insert(keybind_lineNrs, first_btn_line)
      first_btn_line = first_btn_line + 2
    end

    vim.keymap.set("n", "h", "", { buffer = true })
    vim.keymap.set("n", "l", "", { buffer = true })

    vim.keymap.set("n", "k", function()
      local cur = fn.line "."
      local target_line = vim.tbl_contains(keybind_lineNrs, cur) and cur - 2 or keybind_lineNrs[#keybind_lineNrs]
      vim.api.nvim_win_set_cursor(0, { target_line, math.floor(vim.o.columns / 2) - 13 })
    end, { buffer = true })

    vim.keymap.set("n", "j", function()
      local cur = fn.line "."
      local target_line = vim.tbl_contains(keybind_lineNrs, cur) and cur + 2 or keybind_lineNrs[1]
      vim.api.nvim_win_set_cursor(0, { target_line, math.floor(vim.o.columns / 2) - 13 })
    end, { buffer = true })

    -- pressing enter on
    vim.keymap.set("n", "<CR>", function()
      for i, val in ipairs(keybind_lineNrs) do
        if val == fn.line "." then
          local action = config.nvdash.buttons[i][3]

          if type(action) == "string" then
            vim.cmd(action)
          elseif type(action) == "function" then
            action()
          end
        end
      end
    end, { buffer = true })

    -- buf only options
    vim.opt_local.number = false
    vim.api.nvim_buf_set_option(0, "buflisted", false)
    vim.api.nvim_buf_set_option(0, "modifiable", false)
    vim.api.nvim_buf_set_option(0, "buftype", "nofile")
    vim.api.nvim_buf_set_option(0, "filetype", "NvDash")
  end
end

M.toggle = function()
  if vim.g.nvdash_displayed then
    vim.g.nvdash_displayed = false
    vim.cmd "bd"
  else
    vim.g.nvdash_displayed = true
    M.open()
  end
end

return M
