local M = {}
local api = vim.api

M.bufilter = function()
  local bufs = vim.t.bufs or nil

  if not bufs then
    return {}
  end

  for i = #bufs, 1, -1 do
    if not vim.api.nvim_buf_is_valid(bufs[i]) and vim.bo[bufs[i]].buflisted then
      table.remove(bufs, i)
    end
  end

  return bufs
end

M.getBufIndex = function(bufnr)
  for i, value in ipairs(vim.t.bufs) do
    if value == bufnr then
      return i
    end
  end
end

M.tabuflineNext = function()
  local bufs = M.bufilter() or {}
  local curbufIndex = M.getBufIndex(api.nvim_get_current_buf())
  vim.cmd(curbufIndex == #bufs and "b" .. bufs[1] or "b" .. bufs[curbufIndex + 1])
end

M.tabuflinePrev = function()
  local bufs = M.bufilter() or {}
  local curbufIndex = M.getBufIndex(api.nvim_get_current_buf())
  vim.cmd(curbufIndex == 1 and "b" .. bufs[#bufs] or "b" .. bufs[curbufIndex - 1])
end

M.close_buffer = function(bufnr)
  if vim.bo.buftype == "terminal" then
    vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
  else
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    -- Attempt to delete the buffer using pcall
    local status, err = pcall(function() vim.cmd("confirm bd" .. bufnr) end)
    if status then
      -- Buffer deletion successful, proceed with UI update
      require("nvchad_ui.tabufline").tabuflinePrev()
    else
      -- Buffer deletion failed, print or handle the error message
      print("Failed to delete buffer: " .. err)
    end
  end
end


-- closes tab + all of its buffers
M.closeAllBufs = function(action)
  local bufs = vim.t.bufs

  if action == "closeTab" then
    vim.cmd "tabclose"
  end

  for _, buf in ipairs(bufs) do
    M.close_buffer(buf)
  end

  if action ~= "closeTab" then
    vim.cmd "enew"
  end
end

-- closes all bufs except current one
M.closeOtherBufs = function()
  for _, buf in ipairs(vim.t.bufs) do
    if buf ~= api.nvim_get_current_buf() then
      vim.api.nvim_buf_delete(buf, {})
    end
  end

  vim.cmd "redrawtabline"
end

M.move_buf = function(n)
  local bufs = vim.t.bufs

  for i, bufnr in ipairs(bufs) do
    if bufnr == vim.api.nvim_get_current_buf() then
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

return M
