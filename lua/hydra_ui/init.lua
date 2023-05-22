local new_cmd = vim.api.nvim_create_user_command

new_cmd("HydraVimDash", function()
  if vim.g.nvdash_displayed then
    vim.cmd "bd"
  else
    require("hydra_ui.dash").open(vim.api.nvim_create_buf(false, true))
  end
end, {})

if vim.g.hydravim_dash then
  vim.defer_fn(function()
    require("hydra_ui.dash").open()
  end, 0)
end

  vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if vim.bo.filetype == "dash" then
      vim.cmd "HydraVimDash"
    end
  end,
})
