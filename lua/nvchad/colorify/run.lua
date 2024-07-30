local fn = vim.fn
local api = vim.api
local ns = api.nvim_create_namespace "Colorify"
local conf = require("nvconfig").colorify

api.nvim_set_hl_ns(ns)

local get_extmarks = api.nvim_buf_get_extmarks

local highlight = require "nvchad.colorify.highlight"

local del_extmarks_on_textchange = function(buf)
  vim.b[buf].colorify_attached = true

  api.nvim_buf_attach(buf, false, {
    -- s = start, e == end
    on_bytes = function(_, b, _, s_row, s_col, _, old_e_row, old_e_col, _, _, new_e_col, _)
      -- old_e_row = old deleted lines!
      -- new_e_col isnt 0 when cursor pos has changed
      if old_e_row == 0 and new_e_col == 0 and old_e_col == 0 then
        return
      end

      local row1, col1, row2, col2

      if old_e_row > 0 then
        row1, col1, row2, col2 = s_row, 0, s_row + old_e_row, 0
      else
        row1, col1, row2, col2 = s_row, s_col, s_row, s_col + old_e_col
      end

      local ms = get_extmarks(b, ns, { row1, col1 }, { row2, col2 }, { overlap = true })

      for _, mark in ipairs(ms) do
        api.nvim_buf_del_extmark(b, ns, mark[1])
      end
    end,
    on_detach = function()
      vim.b[buf].colorify_attached = false
    end,
  })
end

local function colorify_lines(args)
  local buf = args.buf

  if not vim.bo[buf].buflisted then
    return
  end

  local winid = vim.fn.bufwinid(buf)

  local min = fn.line("w0", winid) - 1
  local max = fn.line("w$", winid) + 1

  if args.event == "TextChangedI" then
    local cur_linenr = fn.line(".", winid) - 1

    if conf.highlight.hex then
      highlight.hex(ns, buf, cur_linenr, api.nvim_get_current_line())
    end

    if conf.highlight.lspvars then
      highlight.lsp_var(ns, buf, cur_linenr)
    end
    return
  end

  local lines = api.nvim_buf_get_lines(buf, min, max, false)

  if conf.highlight.hex then
    for i, str in ipairs(lines) do
      highlight.hex(ns, buf, min + i - 1, str)
    end
  end

  if conf.highlight.lspvars then
    highlight.lsp_var(ns, buf, nil, min, max)
  end

  if args.event == "BufEnter" and not vim.b[buf].colorify_attached then
    del_extmarks_on_textchange(buf)
  end
end

api.nvim_create_autocmd({
  "TextChanged",
  "TextChangedI",
  "TextChangedP",
  "VimResized",
  "LspAttach",
  "WinScrolled",
  "BufEnter",
}, {
  callback = colorify_lines,
})
