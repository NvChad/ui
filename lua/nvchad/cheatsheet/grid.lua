dofile(vim.g.base46_cache .. "nvcheatsheet")
local api = vim.api
local ch = require "nvchad.cheatsheet"
local state = ch.state

local ascii = {
  "                                      ",
  "                                      ",
  "                                      ",
  "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
  "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
  "                                      ",
  "                                      ",
  "                                      ",
}

return function(buf, win, action)
  action = action or "open"

  local ns = api.nvim_create_namespace "nvcheatsheet"

  if action == "open" then
    state.mappings_tb = ch.organize_mappings()
  end

  buf = buf or api.nvim_create_buf(false, true)
  win = win or api.nvim_get_current_win()

  api.nvim_set_current_win(win)

  -- add left padding (strs) to ascii so it looks centered
  local ascii_header = vim.tbl_values(ascii)
  local ascii_padding = (api.nvim_win_get_width(win) / 2) - (#ascii_header[1] / 2)

  for i, str in ipairs(ascii_header) do
    ascii_header[i] = string.rep(" ", ascii_padding) .. str
  end

  local ascii_headerlen = #ascii_header

  vim.bo[buf].ma = true

  local column_width = 0

  for _, section in pairs(state.mappings_tb) do
    for _, mapping in pairs(section) do
      local txt = vim.fn.strdisplaywidth(mapping[1] .. mapping[2])
      column_width = column_width > txt and column_width or txt
    end
  end

  -- 10 = space between mapping txt , 4 = 2 & 2 space around mapping txt
  column_width = column_width + 10

  local win_width = vim.o.columns - vim.fn.getwininfo(api.nvim_get_current_win())[1].textoff - 6
  local columns_qty = math.floor(win_width / column_width)
  columns_qty = (win_width / column_width < 10 and columns_qty == 0) and 1 or columns_qty
  column_width = math.floor((win_width - (column_width * columns_qty)) / columns_qty) + column_width

  -- add mapping tables with their headings as key names
  local cards = {}
  local emptyline = string.rep(" ", column_width)

  for name, section in pairs(state.mappings_tb) do
    name = " " .. name .. " "
    for _, mapping in ipairs(section) do
      if not cards[name] then
        cards[name] = {}
      end

      table.insert(cards[name], { { emptyline, "nvchsection" } })

      local whitespace_len = column_width - 4 - vim.fn.strdisplaywidth(mapping[1] .. mapping[2])
      local pretty_mapping = mapping[1] .. string.rep(" ", whitespace_len) .. mapping[2]

      table.insert(cards[name], { { "  " .. pretty_mapping .. "  ", "nvchsection" } })
    end
    table.insert(cards[name], { { emptyline, "nvchsection" } })

    table.insert(cards[name], { { emptyline } })
  end

  -------------------------------------------- distribute cards into columns -------------------------------------------
  local entries = {}

  for key, value in pairs(cards) do
    local headerlen = api.nvim_strwidth(key)
    local pad_l = math.floor((column_width - headerlen) / 2)
    local pad_r = column_width - headerlen - pad_l

    -- center the heading
    key = {
      { string.rep(" ", pad_l), "nvchsection" },
      { key, ch.rand_hlgroup() },
      { string.rep(" ", pad_r), "nvchsection" },
    }

    table.insert(entries, { key, unpack(value) }) -- Create a table with the key and its values
  end

  local columns = {}
  local column_line_lens = {}

  for i = 1, columns_qty do
    columns[i] = {}
  end

  for index, entry in ipairs(entries) do
    local columnIndex = (index - 1) % columns_qty + 1
    table.insert(columns[columnIndex], entry)
    column_line_lens[columnIndex] = (column_line_lens[columnIndex] or 0) + #entry
  end

  ------------------------------------------ set empty lines & extemarks ------------------------------------------
  local max_col_height = math.max(unpack(column_line_lens)) + ascii_headerlen
  local emptylines = {}

  for _ = 1, max_col_height, 1 do
    local txt = string.rep(" ", win_width)
    table.insert(emptylines, txt)
  end

  if action == "redraw" then
    api.nvim_buf_set_lines(buf, 0, -1, false, {})
  end

  api.nvim_buf_set_lines(buf, 0, max_col_height, false, emptylines)

  for i, v in ipairs(ascii_header) do
    api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
      virt_text = { { v, "NvChAsciiHeader" } },
      virt_text_pos = "overlay",
    })
  end

  for col_i, column in ipairs(columns) do
    local row_i = ascii_headerlen - 1
    local col_start = (col_i - 1) * (column_width + (col_i == 1 and 0 or 2))

    for _, val in ipairs(column) do
      for i, v in ipairs(val) do
        api.nvim_buf_set_extmark(buf, ns, row_i + i, col_start, {
          virt_text = v,
          virt_text_pos = "overlay",
        })
      end

      row_i = row_i + #val
    end
  end

  if action == "redraw" then
    return
  end

  api.nvim_set_current_buf(buf)
  ch.autocmds(buf)
end
