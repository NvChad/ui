local api = vim.api

return function(lines)
  local w = 0

  for _, v in ipairs(lines) do
    if #v[1] ~= 0 then
      v[1] = "  " .. v[1] .. "   "
    end

    local strw = api.nvim_strwidth(v[1])

    if w < strw then
      w = strw
    end
  end

  table.insert(lines, 1, { '' })
  table.insert(lines,  { '' })

  local buf = api.nvim_create_buf(false, true)

  local win = api.nvim_open_win(buf, true, {
    row = math.floor((vim.o.lines - #lines) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    width = w,
    height = #lines,
    relative = "editor",
    style = "minimal",
    border = "single",
    title={{"  NvChad News ", "healthSuccess"}},
    title_pos = "center",
  })

   vim.wo[win].winhl = "FloatBorder:Comment"

  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { line[1] })
    vim.api.nvim_buf_add_highlight(buf, -1, line[2] or "", i - 1, 0, -1)
  end

  vim.keymap.set("n", "q", "<cmd> q<cr>")
  vim.keymap.set("n", "<esc>", "<cmd> q<cr>")
end
