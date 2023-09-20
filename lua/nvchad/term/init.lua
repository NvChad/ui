require "base46.term"

local api = vim.api
local g = vim.g
local M = {}

g.nvchad_terms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
}

-------------------------- util funcs -----------------------------
-- works only for non floating windows
M.resize = function(opts)
  local val = pos_data[opts.pos]
  local size = vim.o[val.area] * opts.size
  api["nvim_win_set_" .. val.resize](0, math.floor(size))
end

M.prettify = function(winnr, bufnr)
  vim.wo[winnr].number = false
  vim.wo[winnr].relativenumber = false
  vim.bo[bufnr].buflisted = false
  vim.wo[winnr].winfixheight = true
  vim.wo[winnr].winfixwidth = true
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

------------------------- user api -------------------------------
M.new = function(opts, existing_buf, isToggle)
  vim.cmd(opts.pos)

  local buf = existing_buf or vim.api.nvim_create_buf(false, true)
  local win = api.nvim_get_current_win()
  opts.win = win

  M.prettify(win, buf)

  if opts.size then
    M.resize(opts)
  end

  api.nvim_win_set_buf(win, buf)

  -- handle cmd opt
  local shell = vim.o.shell
  local cmd = shell

  if opts.cmd and (not opts.id or isToggle) then
    cmd = { shell, "-c", opts.cmd .. "; " .. shell }
  end

  M.save_term_info(opts, buf)

  if not opts.id or isToggle then
    vim.fn.termopen(cmd)
  end
end

M.toggle = function(opts)
  local x = g.nvchad_terms[opts.id]

  if x == nil or not api.nvim_buf_is_valid(x.bufnr) then
    M.new(opts, nil, true)
  elseif vim.fn.bufwinid(x.bufnr) == -1 then
    M.new(opts, x.bufnr)
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

return M
