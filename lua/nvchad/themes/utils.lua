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

M.reload_theme = function(name)
  require("nvconfig").base46.theme = name
  require("base46").load_all_highlights()
  require("plenary.reload").reload_module "volt.highlights"
  require "volt.highlights"
end

return M
