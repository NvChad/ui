local api = vim.api
local nvmark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw

local MouseMove = vim.keycode "<MouseMove>"
local LeftMouse = vim.keycode "<LeftMouse>"

local get_virt_text = function(tb, n)
  for _, val in ipairs(tb) do
    if val.col_start <= n and val.col_end >= n then
      return val
    end
  end
end

local run_func = function(foo)
  if type(foo) == "function" then
    foo()
  elseif type(foo) == "string" then
    vim.cmd(foo)
  end
end

local function set_cursormoved_autocmd(buf)
  local v = nvmark_state[buf]

  api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local cursor_pos = api.nvim_win_get_cursor(0)
      local row, col = cursor_pos[1], cursor_pos[2]

      if v.clickables[row] then
        local virtt = get_virt_text(v.clickables[row], col)

        if virtt then
          local actions = virtt.actions
          run_func(type(actions) == "table" and actions.click or actions)
        end
      end
    end,
  })
end

local function handle_mouse(buf, row, col, key)
  local v = nvmark_state[buf]

  -- clear old hovers!
  if v.hovered_extmarks then
    vim.g.nvmark_hovered = nil
    redraw(buf, v.hovered_extmarks)
    v.hovered_extmarks = nil
  end

  if v.clickables[row] then
    local virtt = get_virt_text(v.clickables[row], col)

    if not virtt then
      return
    end

    local actions = virtt.actions

    if key == LeftMouse then
      run_func(type(actions) == "table" and actions.click or actions)
      return
    end

    if key == MouseMove and type(actions) == "table" and actions.hover then
      if actions.hover.callback then
        actions.hover.callback()
      end

      vim.g.nvmark_hovered = actions.hover.id or nil
      redraw(buf, actions.hover.redraw)
      v.hovered_extmarks = actions.hover.redraw
    end
  end
end

return function(opts)
  for _, buf in ipairs(opts.bufs) do
    set_cursormoved_autocmd(buf)
  end

  if not opts.hover then
    return
  end

  vim.o.mousemoveevent = true

  vim.on_key(function(key)
    local mousepos = vim.fn.getmousepos()
    local cur_win = mousepos.winid
    local cur_buf = api.nvim_win_get_buf(cur_win)

    if not vim.tbl_contains(opts.bufs, cur_buf) then
      return
    end

    if key == MouseMove or key == LeftMouse then
      handle_mouse(cur_buf, mousepos.line, mousepos.column - 1, key)
    end
  end)
end
