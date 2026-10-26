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

  for i = 1, columns_qty do
    columns[i] = {}
  end

  for index, entry in ipairs(entries) do
    local columnIndex = (index - 1) % columns_qty + 1
    table.insert(columns[columnIndex], entry)
  end

  ------------------------------------------ build rows ------------------------------------------
  local rows = {}

  for _, str in ipairs(ascii_header) do
    table.insert(rows, { { str, "NvChAsciiHeader" } })
  end

  local column_rows = {}
  local height = 0

  for col_i, column in ipairs(columns) do
    column_rows[col_i] = {}

    for _, card in ipairs(column) do
      for _, row in ipairs(card) do
        table.insert(column_rows[col_i], row)
      end
    end

    height = math.max(height, #column_rows[col_i])
  end

  for row_i = 1, height do
    local row = {}

    for col_i = 1, #columns do
      vim.list_extend(row, column_rows[col_i][row_i] or { { emptyline } })

      if col_i < #columns then
        table.insert(row, { "  " })
      end
    end

    table.insert(rows, row)
  end

  ch.render(buf, rows)

  if action == "redraw" then
    return
  end

  api.nvim_set_current_buf(buf)
  ch.autocmds(buf)
end
