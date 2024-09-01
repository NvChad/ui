local api = vim.api
local nvmark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw

local keys = {
  LeftMouse = vim.keycode "<LeftMouse>",
  LeftDrag = vim.keycode "<LeftDrag>",
  MouseMove = vim.keycode "<MouseMove>",
}

local get_virt_text = function(tb, n)
  for _, val in ipairs(tb) do
    if val.col_start <= n and val.col_end >= n then
      return val
    end
  end
end

local function interactivity(buf, key, row, col, opts)
  local v = nvmark_state[buf]

  -- clear old hovers!
  if opts.hover and key == keys.MouseMove and v.hovered_extmarks then
    vim.g.nvmark_hovered = nil
    redraw(buf, v.hovered_extmarks)
    v.hovered_extmarks = nil
  end

  if v.clickables[row] then
    local virtt = get_virt_text(v.clickables[row], col)

    if not virtt then
      return
    end

    if type(virtt.actions) == "function" then
      virtt.actions = { click = virtt.actions }
    end

    local actions = virtt.actions

    if opts.hover and actions.hover and key == keys.MouseMove then
      if actions.hover.callback then
        actions.hover.callback()
      end

      vim.g.nvmark_hovered = actions.hover.id or nil
      redraw(buf, actions.hover.redraw)
      v.hovered_extmarks = actions.hover.redraw

      ---------------- click ----------------
    elseif key == keys.LeftMouse or key == keys.LeftDrag then
      if type(actions.click) == "string" then
        vim.cmd(actions.click)
      else
        actions.click()
      end
    end
  end
end

return function(opts)
  if opts.hover then
    vim.o.mousemoveevent = true
  end

  vim.on_key(function(key)
    local mousepos = vim.fn.getmousepos()
    local cur_win = mousepos.winid
    local cur_buf = api.nvim_win_get_buf(cur_win)

    if not vim.tbl_contains(opts.bufs, cur_buf) then
      return
    end

    if not opts.hover then
      if key == keys.LeftMouse or key == keys.LeftDrag then
        local row, col = mousepos.line, mousepos.column - 1
        interactivity(cur_buf, key, row, col, opts)
      end

      return
    end

    if key == keys.LeftMouse or key == keys.LeftDrag or key == keys.MouseMove then
      local row, col = mousepos.line, mousepos.column - 1
      interactivity(cur_buf, key, row, col, opts)
    end
  end)
end
