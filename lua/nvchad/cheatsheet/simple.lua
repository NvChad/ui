local api = vim.api
local genstr = string.rep
local strw = api.nvim_strwidth
local ch = require "nvchad.cheatsheet"
local state = ch.state
local gapx = 10
local heading = {
  "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
  "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
}

dofile(vim.g.base46_cache .. "nvcheatsheet")

api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "nvcheatsheet" then
      vim.g.nvcheatsheet_displayed = false
    end
  end,
})

return function(buf, win, action)
  action = action or "open"

  local ns = api.nvim_create_namespace "nvcheatsheet"
  local win_w = api.nvim_win_get_width(0)

  if action == "open" then
    state.mappings_tb = ch.organize_mappings()
  else
    vim.bo[buf].ma = true
  end

  buf = buf or api.nvim_create_buf(false, true)
  win = win or api.nvim_get_current_win()

  api.nvim_set_current_win(win)

  -- Find largest string i.e mapping desc among all mappings
  local max_strlen = 0

  for _, section in pairs(state.mappings_tb) do
    for _, v in ipairs(section) do
      local curstrlen = strw(v[1]) + strw(v[2])
      max_strlen = max_strlen < curstrlen and curstrlen or max_strlen
    end
  end

  local box_w = max_strlen + gapx + 5

  local function addpadding(str)
    local pad = box_w - strw(str)
    local l_pad = math.floor(pad / 2)
    str = str:gsub("^%l", string.upper)
    return genstr(" ", l_pad) .. str .. genstr(" ", pad - l_pad)
  end

  local lines = {
    { genstr(" ", box_w), "NvChAsciiHeader" },
    { addpadding(heading[1]), "NvChAsciiHeader" },
    { addpadding(heading[2]), "NvChAsciiHeader" },
    { genstr(" ", box_w), "NvChAsciiHeader" },
    { "" },
  }

  local sections = vim.tbl_keys(state.mappings_tb)
  table.sort(sections)

  for _, name in ipairs(sections) do
    table.insert(lines, { addpadding(name), "NvChheading" })
    table.insert(lines, { genstr(" ", box_w), "NvChSection" })

    for _, val in ipairs(state.mappings_tb[name]) do
      local pad = max_strlen - strw(val[1]) - strw(val[2]) + gapx
      local str = "  " .. val[1] .. genstr(" ", pad) .. val[2] .. "   "

      table.insert(lines, { str, "NvChSection" })
      table.insert(lines, { genstr(" ", #str), "NvChSection" })
    end

    table.insert(lines, { "" })
  end

  local start_col = math.floor(win_w / 2) - math.floor(box_w / 2)

  -- make columns drawable
  for i = 1, #lines, 1 do
    api.nvim_buf_set_lines(buf, i, i, false, { string.rep(" ", win_w - 10) })
  end

  for row, val in ipairs(lines) do
    local opts = { virt_text_pos = "overlay", virt_text = { val } }
    api.nvim_buf_set_extmark(buf, ns, row, start_col, opts)
  end

  if action ~= "redraw" then
    api.nvim_set_current_buf(buf)
    ch.autocmds(buf)
  end
end
