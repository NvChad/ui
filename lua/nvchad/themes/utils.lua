local M = {}

M.filter = function(tb, str)
  local strlen = #str
  local result = {}

  for _, word in ipairs(tb) do
    if str == word:sub(1, strlen) then
      table.insert(result, word)
    end
  end

  for _, word in ipairs(tb) do
    if string.find(word, str) and not vim.tbl_contains(result, word) then
      table.insert(result, word)
    end
  end

  return #result == 0 and tb or result
end

return M
