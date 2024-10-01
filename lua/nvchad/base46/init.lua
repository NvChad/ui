local M = {}

---@param tb Base46Integrations[]
M.load = function(tb)
  for _, v in ipairs(tb) do
    dofile(vim.g.base46_cache .. v)
  end
end

return M
