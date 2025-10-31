local M = {}
local api = vim.api
local fn = vim.fn
local strw = api.nvim_strwidth
local opts = require("nvconfig").nvdash

local map = function(keys, action, buf)
  for _, v in ipairs(keys) do
    vim.keymap.set("n", v, action, { buffer = buf })
  end
end

local function btn_gap(txt1, txt2, max_str_w)
  local btn_len = strw(txt1) + #txt2
  local spacing = max_str_w - btn_len
  return txt1 .. string.rep(" ", spacing) .. txt2
end

local multicolumn_strw = function(tb, buf)
  local pad = tb.pad or 0
  local c = 0 - pad

  for _, v in ipairs(tb) do
    pad = (v.pad and v.pad ~= "full" and v.pad) or pad
    c = c + strw(v.txt) + pad

    if buf and v.keys then
      map({ v.keys }, "<cmd>" .. v.cmd .. "<cr>", buf)
    end
  end

  return c
end

local function multicolumn_virt_texts(tb, total_w, virt_w)
  local line = {}

  for _, v in ipairs(tb) do
    local txt = type(v.txt) == "string" and v.txt or v.txt()
    table.insert(line, { txt, v.hl })

    local pad = v.pad == "full" and total_w - virt_w or v.pad
    table.insert(line, { string.rep(" ", pad or tb.pad or 0) })
  end

  return line
end

M.open = function(buf, win, action)
  action = action or "open"

  win = win or api.nvim_get_current_win()

  if not vim.bo.buflisted and action == "open" then
    if vim.t.bufs[1] then
      win = vim.fn.bufwinid(vim.t.bufs[1])
      api.nvim_set_current_win(win)
    end
  end

  local ns = api.nvim_create_namespace "nvdash"
  local winh = api.nvim_win_get_height(win)
  local winw = api.nvim_win_get_width(win)
  buf = buf or vim.api.nvim_create_buf(false, true)

  vim.g.nvdash_buf = buf
  vim.g.nvdash_win = win

  local nvdash_w = 0

  if action == "open" then
    api.nvim_win_set_buf(0, buf)
  end

  opts.header = type(opts.header) == "function" and opts.header() or opts.header

  local ui = {}

  ------------------------ find largest string's width -----------------------------
  for _, v in ipairs(opts.header) do
    local headerw = strw(v)
    if headerw > nvdash_w then
      nvdash_w = headerw
    end

    local col = math.floor((winw / 2) - math.floor(strw(v) / 2)) - 6
    local opt = { virt_text_win_col = col, virt_text = { { v, "NvDashAscii" } } }
    table.insert(ui, opt)
  end

  opts.buttons = type(opts.buttons) == "table" and opts.buttons or opts.buttons()

  local groups_maxw = {}
  local btn_widths = {}
  local key_lines = {}

  for i, v in ipairs(opts.buttons) do
    local w

    if v.multicolumn then
      w = multicolumn_strw(v, action == "open" and buf or nil)
      btn_widths[i] = w
    else
      w = strw(type(v.txt) == "string" and v.txt or v.txt() .. (v.keys or ""))
    end

    if nvdash_w < w then
      nvdash_w = w
    end

    if v.group then
      groups_maxw[v.group] = groups_maxw[v.group] or 0

      if groups_maxw[v.group] < w then
        groups_maxw[v.group] = w
      end
    end
  end

  for i, v in ipairs(opts.buttons) do
    local w = nvdash_w
    local col, opt

    if v.multicolumn then
      if v.content == "fit" or v.group then
        w = groups_maxw[v.group] or btn_widths[i]
      end

      col = math.floor((winw / 2) - math.floor(w / 2)) - 6
      opt = { virt_text_win_col = col, virt_text = multicolumn_virt_texts(v, w, btn_widths[i]) }
    else
      local str = type(v.txt) == "string" and v.txt or v.txt()
      if v.content == "fit" or v.group then
        w = groups_maxw[v.group] or strw(str)
      end

      str = v.rep and string.rep(str, w) or str
      str = v.keys and btn_gap(str, v.keys, w) or str
      col = math.floor((winw / 2) - math.floor(w / 2)) - 6
      opt = { virt_text_win_col = col, virt_text = { { str, v.hl or "NvdashButtons" } } }
    end

    table.insert(ui, opt)

    if v.cmd then
      table.insert(key_lines, { i = #ui, cmd = v.cmd, col = col })
    end

    if not v.no_gap then
      table.insert(ui, { virt_text = { { "" } } })
    end

    if v.keys then
      map({ v.keys }, "<cmd>" .. v.cmd .. "<cr>", buf)
    end
  end

  ----------------------- save display txt -----------------------------------------
  local dashboard_h = #ui + 3

  -- if screen height is small
  winh = dashboard_h > winh and dashboard_h or winh

  local row_i = math.floor((winh / 2) - (dashboard_h / 2))

  for i, v in ipairs(key_lines) do
    key_lines[i].i = v.i + row_i + 1
  end

  -- make all lines available
  local empty_str = {}
  for i = 1, winh do
    empty_str[i] = ""
  end

  ------------------------------ EXTMARKS : set text + highlight -------------------------------
  api.nvim_buf_set_lines(buf, 0, -1, false, empty_str)

  for i, v in ipairs(ui) do
    api.nvim_buf_set_extmark(buf, ns, row_i + i, 0, v)
  end

  if action == "redraw" then
    return
  end

  ------------------------------------ keybinds ------------------------------------------
  vim.wo[win].virtualedit = "all"

  if key_lines[1] then
    api.nvim_win_set_cursor(win, { key_lines[1].i, key_lines[1].col })
  end

  local key_movements = function(n, cmd)
    local curline = fn.line "."

    for i, v in ipairs(key_lines) do
      if v.i == curline then
        local x = key_lines[i + n] or key_lines[n == 1 and 1 or #key_lines]
        if cmd and x.cmd then
          vim.cmd(x.cmd)
        else
          return { x.i, x.col }
        end
      end
    end
  end

  map({ "k", "<up>" }, function()
    api.nvim_win_set_cursor(win, key_movements(-1, false))
  end, buf)

  map({ "j", "<down>" }, function()
    api.nvim_win_set_cursor(win, key_movements(1, false))
  end, buf)

  map({ "<cr>" }, function()
    key_movements(0, true)
  end, buf)

  require("nvchad.utils").set_cleanbuf_opts("nvdash", buf)

  ----------------------- autocmds -----------------------------
  local group_id = api.nvim_create_augroup("NvdashAu", { clear = true })

  api.nvim_create_autocmd("BufWinLeave", {
    group = group_id,
    buffer = buf,
    callback = function()
      vim.g.nvdash_displayed = false
      api.nvim_del_augroup_by_name "NvdashAu"
    end,
  })

  api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group_id,
    callback = function()
      vim.bo[vim.g.nvdash_buf].ma = true
      require("nvchad.nvdash").open(vim.g.nvdash_buf, vim.g.nvdash_win, "redraw")
    end,
  })
end

return M
