require "base46.term"

local M = {}

vim.g.nvchad_terms = {}

M.prettify = function()
  vim.opt_local.buflisted = false
  vim.opt_local.number = false

  vim.cmd "startinsert"
end

M.save_term_info = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()

  local terms_list = vim.g.nvchad_terms
  terms_list[tostring(bufnr)] = opts
  vim.g.nvchad_terms = terms_list
end

M.get_toggled_bufnr = function(id)
  for bufnr, val in ipairs(vim.g.nvchad_terms) do
    if val.id == id then
      return bufnr
    end
  end
end

M.new = function(opts)
  local resize_cmd = "resize "

  if not opts.size then
    opts.size = math.floor(vim.o.columns / 2)
  end

  resize_cmd = resize_cmd .. " " .. opts.size

  if opts.pos == "vsp" then
    resize_cmd = "vertical " .. resize_cmd
  end

  vim.cmd(opts.pos)
  vim.cmd(resize_cmd)

  if opts.id and M.get_toggled_bufnr(opts.id) then
    M.unhide_term(M.get_toggled_bufnr(opts.id))
  else
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

-- used for the terms telescope picker
M.unhide_term = function(bufnr)
  local term_info = vim.g.nvchad_terms[tostring(bufnr)]
  vim.cmd(term_info.pos)

  M.prettify()
  vim.api.nvim_set_current_buf(bufnr)
end

return M
