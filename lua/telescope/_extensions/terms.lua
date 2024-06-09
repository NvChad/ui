-- Credits to telescope buffer builtin, some code taken from it
-- Src: https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/internal.lua

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"

local conf = require("telescope.config").values
local actions = require "telescope.actions"
local make_entry = require "telescope.make_entry"
local action_state = require "telescope.actions.state"

local function wrapper()
  local term_bufs = vim.g.nvchad_terms or {}
  local buffers = {}

  for buf, _ in pairs(term_bufs) do
    buf = tonumber(buf)
    local element = { bufnr = buf, flag = "", info = vim.fn.getbufinfo(buf)[1] }
    table.insert(buffers, element)
  end

  local bufnrs = vim.tbl_keys(term_bufs)

  if #bufnrs == 0 then
    print "no terminal buffers are opened/hidden!"
    return
  end

  local opts = { bufnr_width = math.max(unpack(bufnrs)) }

  local picker = pickers.new {
    prompt_title = " Pick Term",
    previewer = conf.grep_previewer(opts),
    finder = finders.new_table {
      results = buffers,
      entry_maker = make_entry.gen_from_buffer(opts),
    },
    sorter = conf.generic_sorter(),

    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        -- open term only if its window isnt opened
        if vim.fn.bufwinid(entry.bufnr) == -1 then
          local termopts = vim.g.nvchad_terms[tostring(entry.bufnr)]
          require("nvchad.term").display(termopts)
        end
      end)
      return true
    end,
  }

  picker:find()
end

return require("telescope").register_extension {
  exports = { terms = wrapper },
}
