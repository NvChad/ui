local M = {}
local api = vim.api
local state = require "nvchad.extmarks.state"

local buf_i = 1

M.cycle_bufs = function(bufs)
  buf_i = buf_i == #bufs and 1 or buf_i + 1

  local new_buf = bufs[buf_i]
  local a = vim.fn.bufwinid(new_buf)

  api.nvim_set_current_win(a)
end

M.cycle_clickables = function(buf, step)
  local bufstate = state[buf]
  local lines = vim.tbl_keys(bufstate.clickables)
  local cur_row = api.nvim_win_get_cursor(0)[1]

  local len = #lines
  local from_loop = step > 0 and 1 or len
  local to_loop = step > 0 and len or 1

  for i = from_loop, to_loop, step do
    if (step > 0 and lines[i] > cur_row) or (step < 0 and lines[i] < cur_row) then
      api.nvim_win_set_cursor(0, { lines[i], 0 })
      return
    end
  end
end

M.close = function(val)
  for _, buf in ipairs(val) do
    api.nvim_buf_delete(buf, { force = true })
    -- vim.on_key(nil, nvmark_state[buf].onkey_ns)
    state[buf] = nil
  end

  if val.oldwin then
    api.nvim_set_current_win(val.oldwin)
  end
end

return M
