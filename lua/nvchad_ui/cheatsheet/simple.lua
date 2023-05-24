local mappings_tb = require("core.utils").load_config().mappings -- default & user mappings
local isValid_mapping_TB = require("nvchad_ui.cheatsheet").isValid_mapping_TB

-- filter mappings_tb i.e remove tb which have empty fields
for title, val in pairs(mappings_tb) do
  if not isValid_mapping_TB(val) then
    mappings_tb[title] = nil
  end
end

local api = vim.api
local genStr = string.rep

dofile(vim.g.base46_cache .. "nvcheatsheet")

vim.api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "nvcheatsheet" then
      vim.g.nvcheatsheet_displayed = false
    end
  end,
})

return function()
  local buf = api.nvim_create_buf(false, true)

  local win = require("nvchad_ui.cheatsheet").getLargestWin()
  vim.api.nvim_set_current_win(win)

  local centerPoint = api.nvim_win_get_width(win) / 2

  -- convert "<leader>th" to "<leader> + th"
  local function prettify_Str(str)
    local one, two = str:match "([^,]+)>([^,]+)"
    return one and one .. "> + " .. two or str
  end

  -- Find largest string i.e mapping desc among all mappings
  local largest_str = 0

  local cards = {}

  for heading, modes in pairs(mappings_tb) do
    modes.plugin = nil

    for mode, mappings in pairs(modes) do
      local card_header = mode == "n" and heading or heading .. string.format(" ( %s ) ", mode)

      cards[card_header] = mappings

      if type(mappings) == "table" then
        for keybind, mappingInfo in pairs(mappings) do
          if mappingInfo[2] then
            largest_str = largest_str > #mappingInfo[2] + #prettify_Str(keybind) and largest_str
              or #mappingInfo[2] + #prettify_Str(keybind)
          end
        end
      end
    end
  end

  local lineNumsDesc = {}

  local result = {
    "",
    "                                      ",
    "                                      ",
    "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
    "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
    "                                      ",
    "                                      ",
    "",
  }

  for i, val in ipairs(result) do
    result[i] = genStr(" ", centerPoint - (vim.fn.strwidth(val) / 2) + 4) .. val .. genStr(" ", 12)
    lineNumsDesc[#lineNumsDesc + 1] = val == "" and "emptySpace" or "asciiHeader"
  end

  local horiz_index = 0

  local function Capitalize(str)
    return (str:gsub("^%l", string.upper))
  end

  local function addPadding(str)
    local padding = largest_str + 30 - #str
    return genStr(" ", padding / 2) .. Capitalize(str) .. genStr(" ", padding / 2)
  end

  local mapping_txt_endIndex = 0

  -- sort table
  local sorted_tb_keys = vim.tbl_keys(cards)
  table.sort(sorted_tb_keys, function(a, b)
    return a > b
  end)

  -- Store content in a table in a formatted way
  for _, card_name in pairs(sorted_tb_keys) do
    -- Set section headings
    local heading = addPadding(Capitalize(card_name))
    local padded_heading = genStr(" ", centerPoint - #heading / 2) .. heading -- centered text
    local padding_chars = genStr(" ", centerPoint + (#heading / 2) + 2)

    result[#result + 1] = "  " .. padded_heading
    lineNumsDesc[#lineNumsDesc + 1] = "heading"

    result[#result + 1] = padding_chars
    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

    -- Set section mappings : description & keybinds
    for keybind, mappingInfo in pairs(cards[card_name]) do
      if mappingInfo[2] then
        local emptySpace = largest_str + 30 - #mappingInfo[2] - #prettify_Str(keybind) - 10

        local map = Capitalize(mappingInfo[2]) .. genStr(" ", emptySpace) .. prettify_Str(keybind)
        local txt = genStr(" ", centerPoint - #map / 2) .. map

        result[#result + 1] = "   " .. txt .. "   "

        if mapping_txt_endIndex == 0 then
          mapping_txt_endIndex = #result[#result]
        end

        lineNumsDesc[#lineNumsDesc + 1] = "mapping"

        result[#result + 1] = padding_chars
        lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

        if horiz_index == 0 then
          horiz_index = math.floor(centerPoint - math.floor(#map / 2))
        end
      end
    end

    -- add empty lines after a section
    result[#result + 1] = "  "
    result[#result + 1] = "  "

    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"
    lineNumsDesc[#lineNumsDesc + 1] = "emptySpace"
  end

  -- draw content on buffer
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  -- set highlights
  local nvcheatsheet = vim.api.nvim_create_namespace "nvcheatsheet"

  local hlgroups_types = {
    heading = "NvChHeading",
    mapping = "NvChSection",
    paddingBlock = "NvChSection",
    asciiHeader = "NvChAsciiHeader",
    emptySpace = "none",
  }

  for i, val in ipairs(lineNumsDesc) do
    api.nvim_buf_add_highlight(
      buf,
      nvcheatsheet,
      hlgroups_types[val],
      i,
      horiz_index,
      val == "asciiHeader" and -1 or mapping_txt_endIndex
    )
  end

  api.nvim_set_current_buf(buf)

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

  vim.keymap.set("n", "<ESC>", function()
    require("nvchad_ui.tabufline").close_buffer(buf)
  end, { buffer = buf }) -- use ESC to close
end
