dofile(vim.g.base46_cache .. "nvchad_updater")

local nvim_config = vim.fn.stdpath "config"
local chadrc_config = require("core.utils").load_config()
local config_branch = chadrc_config.options.nvchad_branch

local api = vim.api

local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪢", "󰪣", "󰪤", "󰪥" }
-- local spinners = { "󰸶", "󰸸", "󰸷", "󰸴", "󰸵", "󰸳" }
-- local spinners = { "", "", "", "󰺕", "", "" }
local content = { " ", " ", "" }
local header = " 󰓂 Update status "

return function()
  local local_branch = vim.fn.system { "git", "-C", nvim_config, "branch", "--show-current" }
  local_branch = local_branch:gsub("\n", "")

  if local_branch ~= config_branch then
    print "Updated local branch! reopen neovim & run NvChadUpdate command again"
    vim.fn.system { "git", "-C", nvim_config, "switch", config_branch }
    vim.cmd "exit"
  end

  -- create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  vim.cmd "sp"

  vim.api.nvim_set_current_buf(buf)

  -- local options
  vim.opt_local.buflisted = false
  vim.opt_local.number = false
  vim.opt_local.list = false
  vim.opt_local.relativenumber = false
  vim.opt_local.wrap = false
  vim.opt_local.cul = false

  -- set lines & highlight for updater title
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  local nvUpdater = api.nvim_create_namespace "nvUpdater"
  api.nvim_buf_add_highlight(buf, nvUpdater, "nvUpdaterTitle", 1, 0, -1)

  local git_outputs = {} -- list of commits fill here after 3-4 seconds

  -- update spinner icon until git_outputs is empty
  -- use a timer
  local index = 0

  local timer = vim.loop.new_timer()

  timer:start(0, 100, function()
    if #git_outputs ~= 0 then
      timer:stop()
    end

    vim.schedule(function()
      if #git_outputs == 0 then
        content[2] = header .. " " .. spinners[index % #spinners + 1] .. "  "
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        api.nvim_buf_add_highlight(buf, nvUpdater, "nvUpdaterTitle", 1, 0, #header)
        api.nvim_buf_add_highlight(buf, nvUpdater, "nvUpdaterProgress", 1, #header, -1)
      end
    end)

    index = index + 1
  end)

  local git_fetch_err = false

  local function get_commits_data()
    -- set lines & highlights
    -- using vim.schedule because we cant use set_lines & systemlist in callback
    vim.schedule(function()
      if not git_fetch_err then
        local head_hash = vim.fn.systemlist("git -C " .. nvim_config .. " rev-parse HEAD")

        -- git log --format="format:%h: %s"  HEAD..origin/somebranch
        git_outputs = vim.fn.systemlist(
          "git -C " .. nvim_config .. ' log --format="format:%h: %s" ' .. head_hash[1] .. "..origin/" .. config_branch
        )

        if #git_outputs == 0 then
          git_outputs = { "Already updated!" }
        end
      end

      -- add icon to sentences
      for i, value in ipairs(git_outputs) do
        -- remove : after commit hash too
        git_outputs[i] = "  " .. value:gsub(":", "")
      end

      local success_update = " 󰓂 Update status    "
      local failed_update = " 󰓂 Update status  󰚌 "

      content[2] = git_fetch_err and failed_update or success_update

      -- append gitpull table to content table
      for i = 1, #git_outputs, 1 do
        content[#content + 1] = git_outputs[i]
      end

      -- draw the output on buffer
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

      local title_hl = "nvUpdaterTitle" .. (git_fetch_err and "FAIL" or "DONE")
      local progress_hl = "nvUpdaterProgress" .. (git_fetch_err and "FAIL" or "DONE")

      -- highlight title & finish icon
      api.nvim_buf_add_highlight(buf, nvUpdater, title_hl, 1, 0, #header)
      api.nvim_buf_add_highlight(buf, nvUpdater, progress_hl, 1, #header, -1)

      -- 7 = length of git commit hash aliases + 1 :
      for i = 3, #content do
        api.nvim_buf_add_highlight(buf, nvUpdater, (git_fetch_err and "nvUpdaterFAIL" or "nvUpdaterCommits"), i, 2, 13)
      end

      vim.fn.jobstart({ "git", "pull" }, { silent = true, cwd = nvim_config })
      require("lazy").sync()

      if vim.fn.exists ":MasonUpdate" > 0 then
        vim.cmd "MasonUpdate"
      end
    end)
  end

  vim.fn.jobstart({ "git", "fetch" }, {
    cwd = nvim_config,
    on_exit = function(_, code, _)
      get_commits_data()

      if code ~= 0 then
        git_fetch_err = true
        git_outputs[#git_outputs + 1] = "Failed to update "
        print(" error " .. code)
      end
    end,
  })
end
