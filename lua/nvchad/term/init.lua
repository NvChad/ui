require "base46.term"

local api = vim.api
local g = vim.g
local M = {}

g.nvchad_terms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
}

local config = require("nvconfig").ui.term

-- used for initially resizing terms
vim.g.nvhterm = false
vim.g.nvvterm = false

-------------------------- util funcs -----------------------------
M.resize = function(opts)
  local type = pos_data[opts.pos]
  local size = opts.size and opts.size or config.sizes[opts.pos]
  local new_size = vim.o[type.area] * size
  api["nvim_win_set_" .. type.resize](0, math.floor(new_size))
end

M.prettify = function(winnr, bufnr, hl)
  vim.wo[winnr].number = false
  vim.wo[winnr].relativenumber = false
  vim.wo[winnr].foldcolumn = "0"
  vim.wo[winnr].signcolumn = "no"
  vim.bo[bufnr].buflisted = false

  -- custom highlight
  vim.wo[winnr].winhl = hl or config.hl
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

M.create_float = function(buffer, float_opts)
  local opts = vim.tbl_deep_extend("force", config.float, float_opts or {})

  opts.width = math.ceil(opts.width * vim.o.columns)
  opts.height = math.ceil(opts.height * vim.o.lines)
  opts.row = math.ceil(opts.row * vim.o.lines)
  opts.col = math.ceil(opts.col * vim.o.columns)

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

  if opts.cmd and (toggleStatus == "notToggle") then
    cmd = { shell, "-c", opts.cmd .. "; " .. shell }
  end

  M.save_term_info(opts, buf)

  -- use termopen only for non toggled terms
  if toggleStatus == "notToggle" then
    vim.fn.termopen(cmd)
  end

  vim.g.nvhterm = opts.pos == "sp"
  vim.g.nvvterm = opts.pos == "vsp"
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
M.runner = function(opts)
  local x = g.nvchad_terms[opts.id]

  if x == nil then
    M.new(opts, nil, "notToggle")

    -- if window is visible
  elseif vim.fn.bufwinid(x.bufnr) ~= -1 then
    local job_id = vim.b[x.bufnr].terminal_job_id
    vim.api.nvim_chan_send(job_id, "clear; " .. opts.cmd .. " \n")

    -- if window is not visible
  elseif vim.fn.bufwinid(x.bufnr) == -1 then
    -- if term window is closed by bd or killed
    if not api.nvim_buf_is_valid(x.bufnr) then
      -- delete that bufnr val
      local termbufs = g.nvchad_terms
      termbufs[x.bufnr] = nil
      g.nvchad_terms = termbufs

      M.new(opts, nil, "notToggle")
      return
    end

    M.new(opts, x.bufnr)
  end
end

return M
