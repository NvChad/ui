return function(o)
  local line = {}

  if o.thumb then
    o.w = o.w - 1
  end

  if o.txt then
    table.insert(line, { o.txt .. "  " })
    o.w = o.w - vim.fn.strwidth(line[1][1])
  end

  if o.ratio_txt then
    o.w = o.w - 5
  end

  local active_len = math.floor((o.val / 100) * o.w)
  local ratio = o.ratio_txt and math.floor((active_len / o.w) * 100) or ""
  local step = math.ceil(100 / o.w)

  for i = 1, o.w, 1 do
    local hlgroup = i <= active_len and o.hlon or (o.hloff or "LineNr")

    local char = {
      (o.thumb and i == active_len) and " " or "━",
      -- "━",
      hlgroup,
      function()
        o.onclick(i * step)
      end,
    }

    table.insert(line, char)
  end

  if o.ratio_txt then
    table.insert(line, { "  " .. ratio .. " %", "Comment" })
  end

  return line
end
