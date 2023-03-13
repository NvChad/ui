dofile(vim.g.base46_cache .. "nvcheatsheet")

local nvcheatsheet = vim.api.nvim_create_namespace "nvcheatsheet"
local mappings_tb = require("core.utils").load_config().mappings

vim.api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "nvcheatsheet" then
      vim.g.nvdash_displayed = false
    end
  end,
})

-- cheatsheet header!
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

-- basically the draw function
return function()
  local buf = vim.api.nvim_create_buf(false, true)

  -- add left padding (strs) to ascii so it looks centered
  local ascii_header = vim.tbl_values(ascii)
  local ascii_padding = (vim.api.nvim_win_get_width(0) / 2) - (#ascii_header[1] / 2)

  for i, str in ipairs(ascii_header) do
    ascii_header[i] = string.rep(" ", ascii_padding) .. str
  end

  -- set ascii
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, ascii_header)

  -- convert "<leader>th" to "<leader> + th"
  local function prettify_Str(str)
    local one, two = str:match "([^,]+)>([^,]+)"
    return one and one .. "> + " .. two or str
  end

  -- column width
  local column_width = 0

  for _, modes in pairs(mappings_tb) do
    modes.plugin = nil -- this is useless for the cheathseet

    for _, mappings in pairs(modes) do
      if type(mappings) == "table" then
        for keybind, mappingInfo in pairs(mappings) do
          if mappingInfo[2] then
            column_width = column_width > #mappingInfo[2] + #prettify_Str(keybind) and column_width
              or #mappingInfo[2] + #prettify_Str(keybind)
          end
        end
      end
    end
  end

  -- 10 = space between mapping txt , 4 = 2 & 2 space around mapping txt
  column_width = column_width + 10 + 4

  local win_width = vim.api.nvim_win_get_width(0) - vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff - 4
  local columns_qty = math.floor(win_width / column_width)

  column_width = math.floor((win_width - (column_width * columns_qty)) / columns_qty) + column_width

  -- add mapping tables with their headings as key names
  local cards = {}
  local card_headings = {}

  for name, section in pairs(mappings_tb) do
    for mode, modeMappings in pairs(section) do
      local mode_suffix = (mode == "n" or mode == "plugin") and "" or string.format(" (%s) ", mode)
      local card_name = name .. mode_suffix
      local padding_left = math.floor((column_width - #card_name) / 2)

      -- center the heading
      card_name = string.rep(" ", padding_left)
        .. card_name
        .. string.rep(" ", column_width - #card_name - padding_left)

      card_headings[#card_headings + 1] = card_name

      cards[card_name] = {}
      cards[card_name][#cards[card_name] + 1] = string.rep(" ", column_width)

      if type(modeMappings) == "table" then
        for keystroke, mapping_info in pairs(modeMappings) do
          if mapping_info[2] then
            local whitespace_len = column_width - 4 - #(prettify_Str(keystroke) .. mapping_info[2])
            local pretty_mapping = mapping_info[2] .. string.rep(" ", whitespace_len) .. prettify_Str(keystroke)

            cards[card_name][#cards[card_name] + 1] = "  " .. pretty_mapping .. "  "
            cards[card_name][#cards[card_name] + 1] = string.rep(" ", column_width)
          end
        end
      end

      cards[card_name][#cards[card_name] + 1] = string.rep(" ", column_width)
    end
  end

  -- divide cheatsheet layout into columns
  local columns = {}

  for i = 1, columns_qty, 1 do
    columns[i] = {}
  end

  local function getColumn_height(tb)
    local res = 0

    for _, value in pairs(tb) do
      res = res + #value + 1
    end

    return res
  end

  local function append_table(tb1, tb2)
    for _, val in ipairs(tb2) do
      tb1[#tb1 + 1] = val
    end
  end

  local cards_headings_sorted = vim.tbl_keys(cards)

  table.sort(cards_headings_sorted, function(first, second)
    return first:gsub("%s*", "") < second:gsub("%s*", "")
  end)

  -- imitate masonry layout
  for _, heading in pairs(cards_headings_sorted) do
    for column, mappings in ipairs(columns) do
      if column == 1 and getColumn_height(columns[1]) == 0 then
        columns[1][1] = cards_headings_sorted[1]
        append_table(columns[1], cards[cards_headings_sorted[1]])
        break
      elseif column == 1 and getColumn_height(mappings) < getColumn_height(columns[#columns]) then
        columns[column][#columns[column] + 1] = heading
        append_table(columns[column], cards[heading])
        break
      elseif column == 1 and getColumn_height(mappings) == getColumn_height(columns[#columns]) then
        columns[column][#columns[column] + 1] = heading
        append_table(columns[column], cards[heading])
        break
      elseif column ~= 1 and (getColumn_height(columns[column - 1]) > getColumn_height(mappings)) then
        if not vim.tbl_contains(columns[1], heading) then
          columns[column][#columns[column] + 1] = heading
          append_table(columns[column], cards[heading])
        end
        break
      end
    end
  end

  local longest_column = 0

  for _, value in ipairs(columns) do
    longest_column = longest_column > #value and longest_column or #value
  end

  local max_col_height = 0

  -- get max_col_height
  for _, value in ipairs(columns) do
    max_col_height = max_col_height < #value and #value or max_col_height
  end

  -- fill empty lines with whitespaces
  -- so all columns will have the same height
  for i, _ in ipairs(columns) do
    for _ = 1, max_col_height - #columns[i], 1 do
      columns[i][#columns[i] + 1] = string.rep(" ", column_width)
    end
  end

  local result = vim.tbl_values(columns[1])

  -- merge all the column strings
  for index, value in ipairs(result) do
    local line = value

    for col_index = 2, #columns, 1 do
      line = line .. "  " .. columns[col_index][index]
    end

    result[index] = line
  end

  vim.api.nvim_buf_set_lines(buf, #ascii_header, -1, false, result)

  -- list all hl groups that start with NvChHead
  -- thanks to @max397574 for teaching me
  local highlights_raw = vim.split(vim.api.nvim_exec("filter " .. "NvChHead" .. " hi", true), "\n")
  local highlight_groups = {}

  for _, raw_hi in ipairs(highlights_raw) do
    table.insert(highlight_groups, string.match(raw_hi, "NvChHead" .. "%S+"))
  end

  -- add highlight to the columns
  for i = 0, max_col_height, 1 do
    for column_i, _ in ipairs(columns) do
      local col_start = column_i == 1 and 0 or (column_i - 1) * column_width + ((column_i - 1) * 2)
      local col_end = column_i == 1 and column_width or col_start + column_width

      if columns[column_i][i] then
        -- highlight headings & one line after it
        if vim.tbl_contains(card_headings, columns[column_i][i]) then
          local heading_index = 0
          local heading_end = 0

          -- find index of starting/ending letter
          for char_i = 1, #columns[column_i][i], 1 do
            if columns[column_i][i]:sub(char_i, char_i) ~= " " and heading_index == 0 then
              heading_index = char_i
            elseif columns[column_i][i]:sub(char_i, char_i) ~= " " then
              heading_end = char_i
            end
          end

          -- highlight area around card heading
          vim.api.nvim_buf_add_highlight(buf, nvcheatsheet, "NvChSection", i + #ascii_header - 1, col_start, col_end)

          -- highlight card heading & randomize hl groups for colorful colors
          vim.api.nvim_buf_add_highlight(
            buf,
            nvcheatsheet,
            highlight_groups[math.random(1, #highlight_groups)],
            i + #ascii_header - 1,
            col_start + heading_index - 2,
            col_start + heading_end + 1
          )
          vim.api.nvim_buf_add_highlight(buf, nvcheatsheet, "NvChSection", i + #ascii_header, col_start, col_end)

        -- highlight mappings & one line after it
        elseif string.match(columns[column_i][i], "%s+") ~= columns[column_i][i] then
          vim.api.nvim_buf_add_highlight(buf, nvcheatsheet, "NvChSection", i + #ascii_header - 1, col_start, col_end)
          vim.api.nvim_buf_add_highlight(buf, nvcheatsheet, "NvChSection", i + #ascii_header, col_start, col_end)
        end
      end
    end
  end

  -- set highlights for  ascii header
  for i = 0, #ascii_header - 1, 1 do
    vim.api.nvim_buf_add_highlight(buf, nvcheatsheet, "NvChAsciiHeader", i, 0, -1)
  end

  vim.api.nvim_set_current_buf(buf)

  -- buf only options
  vim.opt_local.buflisted = false
  vim.opt_local.modifiable = false
  vim.opt_local.buftype = "nofile"
  vim.opt_local.filetype = "nvcheatsheet"
  vim.opt_local.number = false
  vim.opt_local.list = false
  vim.opt_local.wrap = false
  vim.opt_local.relativenumber = false
  vim.opt_local.cul = false
end
