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

M.get_mappings = function(mappings, tb_to_add)
  for _, v in ipairs(mappings) do
    local desc = v.desc

    if not desc or (select(2, desc:gsub("%S+", "")) <= 1) then
      goto continue
    end

    local heading = desc:match "%S+" -- get first word
    heading = (v.mode ~= "n" and heading .. " (" .. v.mode .. ")") or heading

    if not tb_to_add[heading] then
      tb_to_add[heading] = {}
    end

    local keybind = string.sub(v.lhs, 1, 1) == " " and "<leader> +" .. v.lhs or v.lhs

    desc = v.desc:match "%s(.+)" -- remove first word from desc

    table.insert(tb_to_add[heading], { desc, keybind })

    ::continue::
  end
end

M.organize_mappings = function(tb_to_add)
  local modes = { "n", "i", "v", "t" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    require("nvchad.cheatsheet").get_mappings(keymaps, tb_to_add)

    local bufkeymaps = vim.api.nvim_buf_get_keymap(0, mode)
    require("nvchad.cheatsheet").get_mappings(bufkeymaps, tb_to_add)
  end

  -- remove groups which have only 1 mapping
  for key, x in pairs(tb_to_add) do
    if(#x <=1) then
      tb_to_add[key] = nil
    end
  end
end

return M
