local api = vim.api
local ns = api.nvim_create_namespace "HexColorHighlight"

api.nvim_set_hl_ns(ns)

local utils = require "colorify.utils"
local set_extmark = api.nvim_buf_set_extmark
local get_extmarks = api.nvim_buf_get_extmarks
local conf = utils.config

local function not_colored(buf, linenr, col, hl_group, opts)
  local ms = get_extmarks(buf, ns, { linenr, col }, { linenr, opts.end_col }, { details = true })
  ms = #ms == 0 and {} or ms[1]

  local old_hl

  if #ms > 0 then
    opts.id = ms[1]
    old_hl = ms[4].hl_group or ms[4].virt_text[1][2]
  end

  return #ms == 0 or old_hl ~= hl_group
end

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

    local colorit = not_colored(buf, linenr, col - 1, hl_group, opts)

    if colorit then
      set_extmark(buf, ns, linenr, col - 1, opts)
    end
  end
end

local function highlight_lspvars(buf, line)
  local param = { textDocument = vim.lsp.util.make_text_document_params() }

  for _, client in pairs(vim.lsp.get_clients { bufnr = buf }) do
    if client.server_capabilities.colorProvider then
      client.request("textDocument/documentColor", param, function(_, resp)
        -- if resp and line then
        --   resp = vim.tbl_filter(function(v)
        --     return v.range["start"].line == line
        --   end, resp)
        -- end

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

          local colorit = not_colored(buf, range_start.line, range_start.character, hl_group, opts)

          if colorit then
            set_extmark(buf, ns, range_start.line, range_start.character, opts)
          end
        end
      end, buf)
    end
  end
end

local function colorify(args)
  local buf = args.buf

  if args.event == "TextChangedI" then
    local cur_line = api.nvim_get_current_line()
    highlight_hex(buf, vim.fn.line ".", cur_line)
    highlight_lspvars(buf, vim.fn.line "." - 1)
  else
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

    for i, line in ipairs(lines) do
      highlight_hex(buf, i, line)
    end

    if vim.bo[buf].buflisted then
      highlight_lspvars(buf)
    end
  end

  if args.event == "BufEnter" then
    api.nvim_buf_attach(args.buf, false, {
      on_bytes = function(_, b, _, line)
        local ms = get_extmarks(b, ns, { line, 0 }, { line, -1 }, {})

        for _, v in ipairs(ms) do
          api.nvim_buf_del_extmark(b, ns, v[1])
        end
      end,
    })
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
