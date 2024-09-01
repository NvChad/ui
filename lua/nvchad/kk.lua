
return {

  {
    name = "  New file",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.create(node)
    end,
    rtxt = "a",
  },

  {
    name = "󰉋  New folder",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.create(node)
    end,
    rtxt = "a",  -- Same key as for creating a new file or directory
  },

  { name = "separator" },

  {
    name = "  Cut",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.cut(node)
    end,
    rtxt = "x",
  },
  {
    name = "  Paste",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.paste(node)
    end,
    rtxt = "p",
  },
  {
    name = "  Copy",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.copy.node(node)
    end,
    rtxt = "c",
  },
  {
    name = "󰴠  Copy absolute path",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.copy.absolute_path(node)
    end,
    rtxt = "gy",
  },

  {
    name = "  Copy relative path",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.copy.relative_path(node)
    end,
    rtxt = "Y",
  },

  { name = "separator" },

  {
    name = "  Rename",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.rename(node)
    end,
    rtxt = "r",
  },

  {
    name = "  Trash",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.trash(node)
    end,
    rtxt = "D",
  },

  {
    name = "  Delete",
    cmd = function()
      local api = require "nvim-tree.api"
      local node = api.tree.get_node_under_cursor()
      api.fs.remove(node)
    end,
    rtxt = "d",
  },

}
