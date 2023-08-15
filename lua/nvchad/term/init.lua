require "base46.term"

local M = {}

vim.g.nvchad_terms = {}

M.prettify = function()
  vim.opt_local.buflisted = false
  vim.opt_local.number = false
  vim.cmd "startinsert"
end

-- term bufnr + their opts in a dict
M.save_term_info = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()

  local terms_list = vim.g.nvchad_terms
  terms_list[tostring(bufnr)] = opts
  vim.g.nvchad_terms = terms_list
end

M.get_toggled_bufnr = function(id)
  for bufnr, val in pairs(vim.g.nvchad_terms) do
    if val.id == id then
      return bufnr
    end
  end
end

M.resize = function(opts)
  local qty = opts.pos == "sp" and "lines" or "columns"
  opts.size = vim.o[qty] * opts.size

  local resize_func = "nvim_win_set_" .. (opts.pos == "sp" and "height" or "width")
  vim.api[resize_func](0, math.floor(opts.size))
end

-- spawn new term based on opts
M.new = function(opts)
  if opts.id and M.get_toggled_bufnr(opts.id) then
    M.unhide_term(M.get_toggled_bufnr(opts.id))
    M.resize(opts)
  else
    vim.cmd(opts.pos)

    -- initially resize terminal
    local cond = (opts.pos == "sp" and not vim.g.nv_hterm) or (opts.pos == "vsp" and not vim.g.nv_vterm)

    if opts.size and (cond or opts.id) then
      M.resize(opts)

      vim.g.nv_hterm = opts.pos == "sp" and true or false
      vim.g.nv_vterm = opts.pos == "vsp" and true or false
    end

    vim.cmd "term"
  end

  M.prettify()

  -- save term info
  M.save_term_info(opts)

  -- run shell command
  if opts.shell_cmd then
    local job_id = vim.b.terminal_job_id

    vim.api.nvim_chan_send(job_id, opts.shell_cmd .. " \n")
    vim.cmd "startinsert"
  end
end

M.toggle = function(opts)
  if not vim.g[opts.id] then
    M.new(opts)
  else
    local buf = M.get_toggled_bufnr(opts.id)
    require("nvchad.tabufline").close_buffer(buf)
  end

  vim.g[opts.id] = not vim.g[opts.id]
end

-- used for the terms telescope picker & toggle func
M.unhide_term = function(bufnr)
  local term_info = vim.g.nvchad_terms[tostring(bufnr)]
  vim.cmd(term_info.pos)

  M.prettify()
  vim.api.nvim_set_current_buf(tonumber(bufnr))
end

return M
