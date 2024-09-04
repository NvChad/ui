local api = vim.api
local M = {}

M.val = function(w, left_txt, xpad, opts)
  opts = opts or {}
  local txt_len = vim.fn.strwidth(left_txt or "")
  w = w - txt_len - (opts.ratio and 5 or 0)

  local col = (api.nvim_win_get_cursor(0)[2] - txt_len - xpad)
  col = opts.thumb and col + 1 or col

  col = col >= w and w or col
  col = col <= 0 and 0 or col

  return math.ceil((col / w) * 100)
end

M.config = function(o)
  local line = {}

  local left_txt_len = vim.fn.strwidth(o.txt or "")

  if o.txt then
    table.insert(line, { o.txt })
    o.w = o.w - left_txt_len
  end

  o.w = (o.ratio_txt and o.w - 5) or o.w

  local active_i = math.ceil((o.val / 100) * o.w)
  local thumb_icon = ""

  if o.thumb then
    thumb_icon = o.thumb_icon or ""
    thumb_icon = thumb_icon .. (o.val < 100 and " " or "")
    thumb_icon = o.val == 0 and "" or thumb_icon
  end

  local active_str = string.rep("━", active_i - vim.fn.strwidth(thumb_icon))

  local activemark = {
    active_str .. thumb_icon,
    o.hlon,
    {
      ui_type = "slider",
      click = function()
        o.actions()
      end,
    },
  }

  local inactivemark = {
    string.rep("━", o.w - active_i),
    o.hloff or "LineNr",
    {
      ui_type = "slider",
      click = function()
        o.actions()
      end,
    },
  }

  table.insert(line, activemark)
  table.insert(line, inactivemark)

  if o.ratio_txt then
    table.insert(line, { "  " .. o.val .. "%", "Comment" })
  end

  return line
end

return M
