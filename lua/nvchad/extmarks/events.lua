local api = vim.api
local nvmark_state = require "nvchad.extmarks.state"

local get_virt_text = function(tb, n)
  for _, val in ipairs(tb) do
    if val.col_start <= n and val.col_end >= n then
      return val
    end
  end
end

local function onclick(buf, row, col)
  local v = nvmark_state[buf]

  if v.clickables[row] then
    local virtt = get_virt_text(v.clickables[row], col)

    if virtt then
      virtt.click()
    end
  end
end

return function(bufs)
  vim.on_key(function(key)
    local mousepos = vim.fn.getmousepos()
    local cur_win = mousepos.winid
    local cur_buf = api.nvim_win_get_buf(cur_win)

    if not vim.tbl_contains(bufs, cur_buf) then
      return
    end

    key = vim.fn.keytrans(key)

    if key == "<LeftMouse>" or key == "<LeftDrag>" then
      local row, col = mousepos.line, mousepos.column - 1
      onclick(cur_buf, row, col)
    end
  end)
end
