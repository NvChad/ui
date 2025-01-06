local M = {}
local api = vim.api
local config = require "nvconfig"

local function capitalize(str)
  return (str:gsub("^%l", string.upper))
end

M.get_mappings = function(mappings, tb_to_add)
  local excluded_groups = require("nvconfig").cheatsheet.excluded_groups

  for _, v in ipairs(mappings) do
    local desc = v.desc

    -- dont include mappings which have \n in their desc
    if not desc or (select(2, desc:gsub("%S+", "")) <= 1) or string.find(desc, "\n") then
      goto continue
    end

    local heading = desc:match "%S+" -- get first word
    heading = (v.mode ~= "n" and heading .. " (" .. v.mode .. ")") or heading

    -- useful for removing groups || <Plug> lhs keymaps from cheatsheet
    if
      vim.tbl_contains(excluded_groups, heading)
      or vim.tbl_contains(excluded_groups, desc:match "%S+")
      or string.find(v.lhs, "<Plug>")
    then
      goto continue
    end

    heading = capitalize(heading)

    if not tb_to_add[heading] then
      tb_to_add[heading] = {}
    end

    local keybind = string.sub(v.lhs, 1, 1) == " " and "<leader> +" .. v.lhs or v.lhs

    desc = v.desc:match "%s(.+)" -- remove first word from desc
    desc = capitalize(desc)

    table.insert(tb_to_add[heading], { desc, keybind })

    ::continue::
  end
end

M.organize_mappings = function()
  local tb_to_add = {}
  local modes = { "n", "i", "v", "t" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    require("nvchad.cheatsheet").get_mappings(keymaps, tb_to_add)

    local bufkeymaps = vim.api.nvim_buf_get_keymap(0, mode)
    require("nvchad.cheatsheet").get_mappings(bufkeymaps, tb_to_add)
  end

  return tb_to_add

  -- remove groups which have only 1 mapping
  -- for key, x in pairs(tb_to_add) do
  --   if #x <= 1 then
  --     tb_to_add[key] = nil
  --   end
  -- end
end

M.autocmds = function(buf)
  require("nvchad.utils").set_cleanbuf_opts("nvcheatsheet", buf)

  local group_id = api.nvim_create_augroup("NvCh", { clear = true })

  api.nvim_create_autocmd("BufWinLeave", {
    group = group_id,
    buffer = buf,
    callback = function()
      vim.g.nvcheatsheet_displayed = false
      api.nvim_del_augroup_by_name "NvCh"
    end,
  })

  api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group_id,
    callback = function()
      require("nvchad.cheatsheet." .. config.cheatsheet.theme)(vim.g.nvch_buf, vim.g.nvch_win, "redraw")
    end,
  })

  vim.keymap.set("n", "q", function()
    require("nvchad.tabufline").close_buffer()
  end, { buffer = buf })

  vim.keymap.set("n", "<ESC>", function()
    require("nvchad.tabufline").close_buffer()
  end, { buffer = buf })

  vim.g.nvch_buf = buf
  vim.g.nvch_win = vim.fn.bufwinid(buf)
end

M.rand_hlgroup = function()
  local hlgroups =
    { "blue", "red", "green", "yellow", "orange", "baby_pink", "purple", "white", "cyan", "vibrant_green", "teal" }

  return "NvChHead" .. hlgroups[math.random(1, #hlgroups)]
end

M.state = {
  mappings_tb = {},
}

return M
