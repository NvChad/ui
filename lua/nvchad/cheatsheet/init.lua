local M = {}

M.getLargestWin = function()
  local largest_win_width = 0
  local largest_win_id = 0

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local tmp_width = vim.api.nvim_win_get_width(winid)

    if tmp_width > largest_win_width then
      largest_win_width = tmp_width
      largest_win_id = winid
    end
  end

  return largest_win_id
end

M.isValid_mapping_TB = function(tbl)
  if type(tbl) ~= "table" or #vim.tbl_keys(tbl) == 0 then
    return false
  end

  return true
end

return M
