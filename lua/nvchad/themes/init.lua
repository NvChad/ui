local M = {}
local api = vim.api
local volt = require "volt"
local ui = require "nvchad.themes.ui"
local state = require "nvchad.themes.state"
local colors = dofile(vim.g.base46_cache .. "colors")

state.ns = api.nvim_create_namespace "NvThemes"

if not state.val then
  state.val = require("nvchad.utils").list_themes()
  state.themes_shown = state.val
end

local gen_word_pad = function()
  local largest = 0

  for i = state.index, state.index + state.limit[state.style], 1 do
    local namelen = #state.val[i]

    if namelen > largest then
      largest = namelen
    end
  end

  state.longest_name = largest
end

M.open = function(opts)
  opts = opts or {}
  state.buf = api.nvim_create_buf(false, true)
  state.input_buf = api.nvim_create_buf(false, true)

  state.style = opts.style or "bordered"

  local style = state.style

  state.icons.user = opts.icon
  state.icon = state.icons.user or state.icons[style]

  gen_word_pad()

  state.w = state.longest_name + state.word_gap + (#state.order * api.nvim_strwidth(state.icon)) + (state.xpad * 2)

  if style == "compact" then
    state.w = state.w + 4 -- 1 x 2 padding on left/right + 2 of scrollbar
  end

  if style == "flat" then
    state.w = state.w + 8
  end

  volt.gen_data {
    {
      buf = state.buf,
      layout = { { name = "themes", lines = ui[state.style] } },
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local h = state.limit[style] + 1

  if style == "flat" or style == "bordered" then
    local step = state.scroll_step[state.style]
    h = (h * step) - 5
  end

  local input_win_opts = {
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - state.w) / 2),
    width = state.w,
    height = 1,
    relative = "editor",
    style = "minimal",
    border = "single",
  }

  if style == "flat" or style == "bordered" then
    input_win_opts.row = input_win_opts.row - 2
  end

  state.input_win = api.nvim_open_win(state.input_buf, true, input_win_opts)

  state.win = api.nvim_open_win(state.buf, false, {
    row = 2,
    col = -1,
    width = state.w,
    height = ((style == "flat" or style == "bordered") and h + 2) or h,
    relative = "win",
    style = "minimal",
    border = "single",
  })

  vim.bo[state.input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(state.input_buf, state.prompt)
  vim.cmd "startinsert"

  if opts.border then
    api.nvim_set_hl(state.ns, "FloatBorder", { link = "Comment" })
    api.nvim_set_hl(state.ns, "Normal", { link = "Normal" })
    vim.wo[state.input_win].winhl = "Normal:Normal"
  else
    vim.wo[state.input_win].winhl = "Normal:ExBlack2Bg,FloatBorder:ExBlack2Border"
    api.nvim_set_hl(state.ns, "Normal", { link = "ExDarkBg" })
    api.nvim_set_hl(state.ns, "FloatBorder", { link = "ExDarkBorder" })
  end

  api.nvim_set_hl(state.ns, "NScrollbarOff", { fg = colors.one_bg2 })
  api.nvim_win_set_hl_ns(state.win, state.ns)
  api.nvim_set_current_win(state.input_win)

  local volt_opts = { h = #state.val, w = state.w }

  if state.style == "flat" or state.style == "bordered" then
    local step = state.scroll_step[state.style]
    volt_opts.h = (volt_opts.h * step) + 2
  end

  volt.run(state.buf, volt_opts)

  ----------------- keymaps --------------------------
  volt.mappings {
    bufs = { state.buf, state.input_buf },
    after_close = function()
      if not state.confirmed then
        require("plenary.reload").reload_module "chadrc"
        local theme = require("chadrc").base46.theme
        require("nvchad.themes.utils").reload_theme(theme)
      end
      require("plenary.reload").reload_module "nvchad.themes"
      vim.cmd.stopinsert()
    end,
  }

  require "nvchad.themes.mappings"

  if opts.mappings then
    opts.mappings(state.input_buf)
  end
end

return M
