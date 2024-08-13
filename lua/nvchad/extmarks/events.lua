local api = vim.api
local nvmark_state = require "nvchad.extmarks.state"

local get_virt_text = function(tb, n)
  for _, val in ipairs(tb) do
    if val.col_start <= n and val.col_end >= n then
      return val
    end
  end
end

return function(buf)
  local v = nvmark_state[buf]

  api.nvim_create_autocmd("CursorMoved", {
    buffer = v.buf,
    callback = function()
      local cursor_pos = api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]

      if v.clickables[row] then
        local virtt = get_virt_text(v.clickables[row], col)

        if virtt then
          virtt.click()
        end
      end
    end,
  })
end
