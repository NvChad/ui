local M = {}
local api = vim.api
local cur_buf = api.nvim_get_current_buf
local set_buf = api.nvim_set_current_buf
local get_opt = api.nvim_get_option_value

local function buf_index(bufnr)
  for i, value in ipairs(vim.t.bufs) do
    if value == bufnr then
      return i
    end
  end
end

M.next = function()
  local bufs = vim.t.bufs
  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf(vim.t.bufs[1])
    return
  end

  set_buf((curbufIndex == #bufs and bufs[1]) or bufs[curbufIndex + 1])
end

M.prev = function()
  local bufs = vim.t.bufs
  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf(vim.t.bufs[1])
    return
  end

  set_buf((curbufIndex == 1 and bufs[#bufs]) or bufs[curbufIndex - 1])
end

M.close_buffer = function(bufnr)
  bufnr = bufnr or cur_buf()

  if vim.bo[bufnr].buftype == "terminal" then
    vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
  else
    local curBufIndex = buf_index(bufnr)
    local bufhidden = vim.bo.bufhidden

    -- force close floating wins or nonbuflisted
    if api.nvim_win_get_config(0).zindex then
      vim.cmd "bw"
      return

      -- handle listed bufs
    elseif curBufIndex and #vim.t.bufs > 1 then
      local newBufIndex = curBufIndex == #vim.t.bufs and -1 or 1
      vim.cmd("b" .. vim.t.bufs[curBufIndex + newBufIndex])

      -- handle unlisted
    elseif not vim.bo.buflisted then
      local tmpbufnr = vim.t.bufs[1]
      api.nvim_set_current_win(vim.fn.bufwinid(bufnr))
      api.nvim_set_current_buf(tmpbufnr)
      vim.cmd("bw" .. bufnr)
      return
    else
      vim.cmd "enew"
    end

    if not (bufhidden == "delete") then
      vim.cmd("confirm bd" .. bufnr)
    end
  end

  vim.cmd "redrawtabline"
end

-- closes tab + all of its buffers
M.closeAllBufs = function(include_cur_buf)
  local bufs = vim.t.bufs

  if include_cur_buf ~= nil and not include_cur_buf then
    table.remove(bufs, buf_index(cur_buf()))
  end

  for _, buf in ipairs(bufs) do
    M.close_buffer(buf)
  end
end

-- closes all other buffers right or left
M.closeBufs_at_direction = function(x)
  local buf_i = buf_index(cur_buf())

  for i, bufnr in ipairs(vim.t.bufs) do
    if (x == "left" and i < buf_i) or (x == "right" and i > buf_i) then
      M.close_buffer(bufnr)
    end
  end
end

M.move_buf = function(n)
  local bufs = vim.t.bufs

  for i, bufnr in ipairs(bufs) do
    if bufnr == cur_buf() then
      if n < 0 and i == 1 or n > 0 and i == #bufs then
        bufs[1], bufs[#bufs] = bufs[#bufs], bufs[1]
      else
        bufs[i], bufs[i + n] = bufs[i + n], bufs[i]
      end

      break
    end
  end

  vim.t.bufs = bufs
  vim.cmd "redrawtabline"
end

M.goto_buf = function(bufnr)
  local cur_win = api.nvim_get_current_win()
  local fixedbuf = api.nvim_get_option_value("winfixbuf", { win = cur_win })

  if fixedbuf then
    for _, v in ipairs(api.nvim_list_wins()) do
      local buflisted = get_opt("buflisted", { buf = api.nvim_win_get_buf(v) })
      local tmp_fixedbuf = get_opt("winfixbuf", { win = v })

      if buflisted and not tmp_fixedbuf then
        api.nvim_set_current_win(v)
        break
      end
    end
  end

  api.nvim_set_current_buf(bufnr)
end

return M
