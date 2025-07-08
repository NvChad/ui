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

local multicolumn_strw = function(tb)
  local c = 0 - tb.pad

  for _, v in ipairs(tb) do
    local pad = v.pad and v.pad ~= "full" and v.pad or tb.pad
    c = c + strw(v.txt) + pad
  end

  return c
end

local function multicolumn_virt_texts(tb, total_w)
  local line = {}
  local virt_w = multicolumn_strw(tb)

  for _, v in ipairs(tb) do
    local txt = type(v.txt) == "string" and v.txt or v.txt()
    table.insert(line, { txt, v.hl })

    v.pad = v.pad == "full" and total_w - virt_w or v.pad

    table.insert(line, { string.rep(" ", v.pad or tb.pad) })
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

  local nvdash_w = 1

  if action == "open" then
    api.nvim_win_set_buf(0, buf)
  end

  opts.header = type(opts.header) == "function" and opts.header() or opts.header

  ------------------------ find largest string's width -----------------------------
  for _, val in ipairs(opts.header) do
    local headerw = strw(val)
    if headerw > nvdash_w then
      nvdash_w = headerw
    end
  end

  opts.buttons = type(opts.buttons) == "table" and opts.buttons or opts.buttons()

  local buttons = {}

  for _, v in ipairs(opts.buttons) do
    local w
    local col, opt
    -- v.align = v.align or 'left'

    if v.multicolumn then
      w = v.align == "left" and nvdash_w or multicolumn_strw(v)
      col = math.floor((winw / 2) - math.floor(w / 2)) - 6
      opt = { virt_text_win_col = col, virt_text = multicolumn_virt_texts(v, w) }
    else
      local str = type(v.txt) == "string" and v.txt or v.txt()
      w = v.align == "left" and nvdash_w or strw(str .. (v.keys or ""))
      str = v.rep and string.rep(str, nvdash_w - 1) or str

      col = math.floor((winw / 2) - math.floor(w / 2)) - 6
      opt = { virt_text_win_col = col, virt_text = { { str, v.hl or "NvdashButtons" } } }
    end

    table.insert(buttons, opt)

    if not v.no_gap then
      table.insert(buttons, { virt_text = { { "" } } })
    end

    if nvdash_w < w then
      nvdash_w = w
    end

    if v.keys then
      map({ v.keys }, "<cmd>" .. v.cmd .. "<cr>", buf)
    end
  end

  ----------------------- save display txt -----------------------------------------
  local dashboard_h = #opts.header + #buttons + 3

  -- if screen height is small
  if dashboard_h > winh then
    winh = dashboard_h + 10
  end

  local row_i = math.floor((winh / 2) - (dashboard_h / 2))
  local col_i = math.floor((winw / 2) - math.floor(nvdash_w / 2)) - 6 -- (5 is textoff)

  -- make all lines available
  local empty_str = {}
  for i = 1, winh do
    empty_str[i] = string.rep("", winw)
  end

  ------------------------------ EXTMARKS : set text + highlight -------------------------------
  api.nvim_buf_set_lines(buf, 0, -1, false, empty_str)
  local key_lines = {}
  local header_h = #opts.header

  for i, v in ipairs(opts.header) do
    local col = math.floor((winw / 2) - math.floor(strw(v) / 2)) - 6
    local opt = { virt_text_win_col = col, virt_text = { { v, "NvDashAscii" } } }
    api.nvim_buf_set_extmark(buf, ns, row_i + i, 0, opt)
  end

  for i, v in ipairs(buttons) do
    api.nvim_buf_set_extmark(buf, ns, row_i + header_h + i, 0, v)
  end

  ------------------------------------ keybinds ------------------------------------------
  vim.wo[win].virtualedit = "all"
  local btn_start_i = row_i + #opts.header

  if col_i > 0 then
    api.nvim_win_set_cursor(win, { btn_start_i, col_i + 5 })
  end

  map({ "k", "<up>" }, function()
    local cur = fn.line "."
    local target_line = cur == key_lines[1].i and key_lines[#key_lines].i or cur - 2
    api.nvim_win_set_cursor(win, { target_line, col_i + 5 })
  end, buf)

  map({ "j", "<down>" }, function()
    local cur = fn.line "."
    local target_line = cur == key_lines[#key_lines].i and key_lines[1].i or cur + 2
    api.nvim_win_set_cursor(win, { target_line, col_i + 5 })
  end, buf)

  map({ "<cr>" }, function()
    local key = vim.tbl_filter(function(item)
      return item.i == fn.line "."
    end, key_lines)

    if key[1] and key[1].cmd then
      vim.cmd(key[1].cmd)
    end
  end, buf)

  require("nvchad.utils").set_cleanbuf_opts("nvdash", buf)

  if action == "redraw" then
    return
  end

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
