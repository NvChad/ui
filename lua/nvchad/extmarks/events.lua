local api = vim.api
local nvmark_state = require "nvchad.extmarks.state"
local redraw = require("nvchad.extmarks").redraw
local cycle_clickables = require("nvchad.extmarks.utils").cycle_clickables

local MouseMove = vim.keycode "<MouseMove>"
local LeftMouse = vim.keycode "<LeftMouse>"
local map = vim.keymap.set

local get_item_from_col = function(tb, n)
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

local function handle_click(buf, by, row, col)
  local v = nvmark_state[buf]

  if not row then
    local cursor_pos = api.nvim_win_get_cursor(0)
    row, col = cursor_pos[1], cursor_pos[2]
  end

  if v.clickables[row] then
    local virt = get_item_from_col(v.clickables[row], col)

    if virt and (by ~= "keyb" or virt.ui_type == "slider") then
      local actions = virt.actions
      run_func(type(actions) == "table" and actions.click or actions)
    end
  end
end

local function set_cursormoved_autocmd(buf)
  api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      handle_click(buf, "keyb")
    end,
  })
end

local function handle_hover(buf_state, buf, row, col)
  -- clear old hovers!
  if buf_state.hovered_extmarks then
    vim.g.nvmark_hovered = nil
    redraw(buf, buf_state.hovered_extmarks)
    buf_state.hovered_extmarks = nil
  end

  if buf_state.hoverables[row] then
    local virt = get_item_from_col(buf_state.hoverables[row], col)

    if virt and virt.hover then
      local hover = virt.hover

      if hover.callback then
        hover.callback()
      end

      vim.g.nvmark_hovered = hover.id or nil
      redraw(buf, hover.redraw)
      buf_state.hovered_extmarks = hover.redraw
    end
  end
end

local buf_mappings = function(buf)
  set_cursormoved_autocmd(buf)

  map("n", "<CR>", function()
    handle_click(buf)
  end, { buffer = buf })

  map("n", "<Tab>", function()
    cycle_clickables(buf, 1)
  end, { buffer = buf })

  map("n", "<S-Tab>", function()
    cycle_clickables(buf, -1)
  end, { buffer = buf })
end

local M = {}

M.bufs = {}

M.add = function(val)
  if type(val) == "table" then
    for _, buf in ipairs(val) do
      table.insert(M.bufs, buf)
      buf_mappings(buf)
    end
  else
    table.insert(M.bufs, val)
    buf_mappings(val)
  end
end

M.enable = function()
  vim.g.extmarks_events = true
  vim.o.mousemev = true

  vim.on_key(function(key)
    local mousepos = vim.fn.getmousepos()
    local cur_win = mousepos.winid
    local cur_buf = api.nvim_win_get_buf(cur_win)

    if vim.tbl_contains(M.bufs, cur_buf) then
      local row, col = mousepos.line, mousepos.column - 1

      if key == MouseMove then
        handle_hover(nvmark_state[cur_buf], cur_buf, row, col)
      elseif key == LeftMouse then
        handle_click(cur_buf, "mouse", row, col)
      end
    end
  end)
end

return M
