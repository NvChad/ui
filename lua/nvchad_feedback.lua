return function()
  local dir = vim.fn.stdpath "data" .. "/nvchad_feedback"

  if not vim.uv.fs_stat(dir) then
    vim.fn.mkdir(dir, "p")
    vim.cmd.bd()
    vim.cmd "h nvchad_feedback | only"
  end
end
