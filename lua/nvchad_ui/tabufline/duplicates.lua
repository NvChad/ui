-- some stuff come from https://github.com/akinsho/bufferline.nvim/blob/main/lua/bufferline/duplicates.lua
local M = {}
local path_sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

function M.ancestor(parts, depth)
  local index = (depth and depth > #parts) and 1 or (#parts - depth) + 1

  -- return table.concat(parts, path_sep, index, #parts)
  local part = parts[index] .. (depth > 2 and "/../" or "/") .. parts[#parts]
  return depth > 1 and part or parts[#parts]
end

local function is_same_path(a_path, b_path, depth)
  local a_index = depth <= #a_path and (#a_path - depth) + 1 or 1
  local b_index = depth <= #b_path and (#b_path - depth) + 1 or 1
  return b_path[b_index] == a_path[a_index]
end

local duplicates = {}

function M.reset()
  duplicates = {}
end

function M.mark(elements, idx, bufirst, bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local name = " No Name "

  if #path == 0 then
    path = name
  else
    name = vim.fn.fnamemodify(path, ":t")
  end

  path = vim.split(path, path_sep, { trimempty = true })

  local current = { idx = idx, name = name, path = path, depth = 1, bufnr = bufnr }
  local duplicate = duplicates[current.name]

  if not duplicate then
    duplicates[current.name] = { current }
  else
    local depth, limit = 1, 10

    for _, element in ipairs(duplicate) do
      local element_depth = 1

      while is_same_path(current.path, element.path, element_depth) do
        if element_depth >= limit then
          break
        end
        element_depth = element_depth + 1
      end

      depth = element_depth > depth and element_depth or depth

      local previous = elements[element.idx - bufirst]

      if previous and previous.name == name and previous.depth < depth then
        previous.depth = depth
      end
    end

    current.depth = depth
    duplicate[#duplicate + 1] = current
  end

  return current
end

return M
