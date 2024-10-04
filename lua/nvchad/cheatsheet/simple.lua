local api = vim.api
local genstr = string.rep
local strw = api.nvim_strwidth
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

return function()
  local ns = api.nvim_create_namespace "nvcheatsheet"
  local mappings_tb = {}
  local win_w = api.nvim_win_get_width(0)
  require("nvchad.cheatsheet").organize_mappings(mappings_tb)

  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_get_current_win()

  api.nvim_set_current_win(win)
  vim.wo[win].winhl = "NormalFloat:Normal"

  -- Find largest string i.e mapping desc among all mappings
  local max_strlen = 0

  for _, section in pairs(mappings_tb) do
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

  local sections = vim.tbl_keys(mappings_tb)
  table.sort(sections)

  for _, name in ipairs(sections) do
    table.insert(lines, { addpadding(name), "NvChheading" })
    table.insert(lines, { genstr(" ", box_w), "NvChSection" })

    for _, val in ipairs(mappings_tb[name]) do
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

  api.nvim_set_current_buf(buf)
  require("nvchad.utils").set_cleanbuf_opts "nvcheatsheet"

  vim.keymap.set("n", "q", function()
    require("nvchad.tabufline").close_buffer()
  end, { buffer = buf })

  vim.keymap.set("n", "<ESC>", function()
    require("nvchad.tabufline").close_buffer()
  end, { buffer = buf })
end
