local api = vim.api
local ns = api.nvim_create_namespace "Colorify"

api.nvim_set_hl_ns(ns)

local utils = require "colorify.utils"
local conf = utils.config
local needs_hl = utils.not_colored
local set_extmark = api.nvim_buf_set_extmark
local get_extmarks = api.nvim_buf_get_extmarks

---------------------------------- highlighters -----------------------------------------------
local function highlight_hex(buf, line, str)
  for col, hex in str:gmatch "()(#%x%x%x%x%x%x)" do
    local hl_group = utils.add_hl(ns, hex)
    local linenr = line - 1
    local end_col = col + #hex - 1

    local opts = { end_col = end_col, hl_group = hl_group }

    if conf.mode == "virtual" then
      opts.hl_group = nil
      opts.virt_text_pos = "inline"
      opts.virt_text = { { conf.virt_txt, hl_group } }
    end

    if needs_hl(buf, ns, linenr, col - 1, hl_group, opts) then
      set_extmark(buf, ns, linenr, col - 1, opts)
    end
  end
end

local function highlight_lspvars(buf, line, rows)
  local param = { textDocument = vim.lsp.util.make_text_document_params() }

  for _, client in pairs(vim.lsp.get_clients { bufnr = buf }) do
    if client.server_capabilities.colorProvider then
      client.request("textDocument/documentColor", param, function(_, resp)
        if resp and line then
          resp = vim.tbl_filter(function(v)
            return v.range["start"].line == line
          end, resp)
        end

        if resp and rows then
          resp = vim.tbl_filter(function(v)
            return v.range["start"].line >= rows.min and v.range["end"].line <= rows.max
          end, resp)
        end

        for _, match in ipairs(resp or {}) do
          local color = match.color
          local r, g, b, a = color.red, color.green, color.blue, color.alpha
          local hex = string.format("#%02x%02x%02x", r * a * 255, g * a * 255, b * a * 255)

          local hl_group = utils.add_hl(ns, hex)

          local range_start = match.range.start
          local range_end = match.range["end"]

          local opts = {
            end_col = range_end.character,
            virt_text_pos = "inline",
            virt_text = { { "󱓻 ", hl_group } },
          }

          if needs_hl(buf, ns, range_start.line, range_start.character, hl_group, opts) then
            set_extmark(buf, ns, range_start.line, range_start.character, opts)
          end
        end
      end, buf)
    end
  end
end

------------------------------- main function ------------------------------------------------
local function colorify(args)
  local buf = args.buf
  local line = vim.fn.line
  local winid = vim.fn.bufwinid(buf)

  local rows = {
    min = line("w0", winid) - 1,
    max = line("w$", winid) + 1,
  }

  if args.event == "TextChangedI" then
    local cur_line = api.nvim_get_current_line()
    highlight_hex(buf, line ".", cur_line)
    highlight_lspvars(buf, line "." - 1)
  else
    local lines = api.nvim_buf_get_lines(buf, rows.min, rows.max, false)

    for i, str in ipairs(lines) do
      highlight_hex(buf, i, str)
    end

    if vim.bo[buf].buflisted then
      highlight_lspvars(buf, nil, rows)
    end
  end

  if args.event == "BufEnter" then
    if not vim.b[buf].colorify_attached then
      vim.b[buf].colorify_attached = true

      api.nvim_buf_attach(args.buf, false, {
        on_bytes = function(_, b, _, linenr, col, _, _, _, old_endcol)
          local ms = get_extmarks(b, ns, { linenr, col }, { linenr, col + old_endcol }, { overlap = true })

          for _, mark in ipairs(ms) do
            api.nvim_buf_del_extmark(b, ns, mark[1])
          end
        end,
        on_detach = function()
          vim.b[buf].colorify_attached = false
        end,
      })
    end
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
  callback = colorify,
})
