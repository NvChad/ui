local M = {}

local mappings_tb = require("core.utils").load_config().mappings -- default & user mappings
local vim_modes = require "nvchad_ui.statusline.modes"

local api = vim.api
local genStr = string.rep

require("base46").load_highlight "nvcheatsheet"

M.draw = function()
  vim.cmd "enew"
  local CenterPoint = api.nvim_win_get_width(0) / 2

  -- convert "<leader>th" to "<leader> + th"
  local function prettify(str)
    local one, two = str:match "([^,]+)>([^,]+)"
    return one and one .. "> + " .. two or str
  end

  -- Find largest string i.e mapping desc among all mappings
  local largest_str = 0

  for _, modes in pairs(mappings_tb) do
    for _, mappings in pairs(modes) do
      if type(mappings) == "table" then
        for keybind, mappingInfo in pairs(mappings) do
          if mappingInfo[2] then
            largest_str = largest_str > #mappingInfo[2] + #prettify(keybind) and largest_str
              or #mappingInfo[2] + #prettify(keybind)
          end
        end
      end
    end
  end

  local lineNumsDesc = {}

  -- Top padding
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
    result[i] = genStr(" ", CenterPoint - (vim.fn.strwidth(val) / 2) + 4) .. val .. genStr(" ", 12)
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

  -- Store content in a table in a formatted way
  for section, modes in pairs(mappings_tb) do
    -- Set section headings
    local heading = addPadding(Capitalize(section))
    local padded_heading = genStr(" ", CenterPoint - #heading / 2) .. heading -- centered text
    local padding_chars = genStr(" ", CenterPoint + (#heading / 2) + 2)

    result[#result + 1] = "  " .. padded_heading
    lineNumsDesc[#lineNumsDesc + 1] = "heading"

    result[#result + 1] = padding_chars
    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

    for mode, mappings in pairs(modes) do
      -- Show Mode heading if its not normal
      if mode ~= "plugin" and mode ~= "n" then
        local mode_name = "--| " .. vim_modes[mode][1] .. " Mode |--"
        mode_name = addPadding(mode_name)

        result[#result + 1] = genStr(" ", CenterPoint - #mode_name / 2 + 2) .. mode_name
        lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

        result[#result + 1] = padding_chars
        lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"
      end

      if type(mappings) == "table" then
        -- Set section mappings : description & keybinds
        for keybind, mappingInfo in pairs(mappings) do
          if mappingInfo[2] then
            local emptySpace = largest_str + 30 - #mappingInfo[2] - #prettify(keybind) - 10
            local map = Capitalize(mappingInfo[2]) .. genStr(" ", emptySpace) .. prettify(keybind)
            local txt = genStr(" ", CenterPoint - #map / 2) .. map

            result[#result + 1] = "    " .. txt .. "   "
            lineNumsDesc[#lineNumsDesc + 1] = "mapping"

            result[#result + 1] = padding_chars
            lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

            horiz_index = horiz_index == 0 and (CenterPoint - math.floor(#map / 2)) or horiz_index
          end
        end
      end
    end

    -- add empty lines after a section
    result[#result + 1] = "  "
    result[#result + 1] = "  "
    result[#result + 1] = "  "

    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"
    lineNumsDesc[#lineNumsDesc + 1] = "emptySpace"
    lineNumsDesc[#lineNumsDesc + 1] = "emptySpace"
  end

  -- draw content on buffer
  api.nvim_buf_set_lines(0, 3, -1, false, result)

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
    api.nvim_buf_add_highlight(0, nvcheatsheet, hlgroups_types[val], i, math.floor(horiz_index), -1)
  end

  -- some options
  vim.opt_local.number = false
  vim.api.nvim_buf_set_option(0, "buflisted", false)
  vim.api.nvim_buf_set_option(0, "modifiable", false)
  vim.api.nvim_buf_set_option(0, "buftype", "nofile")
  vim.api.nvim_buf_set_option(0, "filetype", "NvCheatsheet")
end

return M
