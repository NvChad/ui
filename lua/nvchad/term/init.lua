require "base46.term"

local api = vim.api
local g = vim.g
local M = {}

g.nvchad_terms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
}

local config = require("core.utils").load_config().ui.term

-- used for initially resizing terms
vim.g.nvhterm = false
vim.g.nvvterm = false

-------------------------- util funcs -----------------------------
M.resize = function(opts)
  local val = pos_data[opts.pos]
  local size = vim.o[val.area] * config.sizes[opts.pos]
  api["nvim_win_set_" .. val.resize](0, math.floor(size))
end

M.prettify = function(winnr, bufnr, hl)
  vim.wo[winnr].number = false
  vim.wo[winnr].relativenumber = false
  vim.wo[winnr].foldcolumn = "0"
  vim.bo[bufnr].buflisted = false

  -- custom highlight
  vim.wo[winnr].winhl = hl or "Normal:Normal,WinSeparator:WinSeparator"
  vim.cmd "startinsert"
end

M.save_term_info = function(opts, bufnr)
  local terms_list = g.nvchad_terms
  terms_list[tostring(bufnr)] = opts

  -- store ids for toggledterms instead of bufnr
  if opts.id then
    opts.bufnr = bufnr
    terms_list[opts.id] = opts
  end

  g.nvchad_terms = terms_list
end

M.create_float = function(buffer, user_opts)
  local opts = {
    relative = "editor",
    width = math.ceil(0.5 * vim.o.columns),
    height = math.ceil(0.4 * vim.o.lines),
    row = math.floor(0.3 * vim.o.lines),
    col = math.floor(0.25 * vim.o.columns),
    border = "single",
    style = "minimal",
  }

  opts = vim.tbl_deep_extend("force", opts, user_opts or {})
  vim.api.nvim_open_win(buffer, true, opts)
end

------------------------- user api -------------------------------
M.new = function(opts, existing_buf, toggleStatus)
  local buf = existing_buf or vim.api.nvim_create_buf(false, true)

  local isFloat = opts.pos == "float"

  -- create window
  if isFloat then
    M.create_float(buf, opts.float_opts)
  else
    vim.cmd(opts.pos)
  end

  local win = api.nvim_get_current_win()
  opts.win = win

  M.prettify(win, buf, opts.hl)

  -- resize non floating wins initially + or only when they're toggleable
  if
    (opts.pos == "sp" and not vim.g.nvhterm)
    or (opts.pos == "vsp" and not vim.g.nvvterm)
    or (toggleStatus and opts.pos ~= "float")
  then
    M.resize(opts)
  end

  api.nvim_win_set_buf(win, buf)

  -- handle cmd opt
  local shell = vim.o.shell
  local cmd = shell

  if opts.cmd and (not opts.id or toggleStatus == "notToggle") then
    cmd = { shell, "-c", opts.cmd .. "; " .. shell }
  end

  M.save_term_info(opts, buf)

  -- use termopen only for non toggled terms
  if (not opts.id) or (toggleStatus == "notToggle") then
    vim.fn.termopen(cmd)
  end

  if opts.pos == "sp" then
    vim.g.nvhterm = true
  elseif opts.pos == "vsp" then
    vim.g.nvvterm = true
  end
end

M.toggle = function(opts)
  local x = g.nvchad_terms[opts.id]

  if x == nil or not api.nvim_buf_is_valid(x.bufnr) then
    M.new(opts, nil, "notToggle")
  elseif vim.fn.bufwinid(x.bufnr) == -1 then
    M.new(opts, x.bufnr, "isToggle")
  else
    api.nvim_win_close(x.win, true)
  end
end

-- spawns term with *cmd & runs the *cmd if the keybind is run again
M.refresh_cmd = function(opts)
  if not opts.cmd then
    print "cmd opt is needed!"
    return
  end

  local x = g.nvchad_terms[opts.id]

  if x == nil then
    M.new(opts, nil, true)
  elseif vim.fn.bufwinid(x.bufnr) == -1 then
    M.new(opts, x.bufnr)
    -- ensure that the buf is displayed on a window i.e visible to neovim!
  elseif vim.fn.bufwinid(x.bufnr) ~= -1 then
    local job_id = vim.b[x.bufnr].terminal_job_id
    vim.api.nvim_chan_send(job_id, "clear; " .. opts.cmd .. " \n")
  end
end

-- autoinsert when entering term buffers
if config.behavior.auto_insert then
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "term://*",
    callback = function()
      vim.cmd "startinsert"
    end,
  })
end

return M
