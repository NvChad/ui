local lsp = vim.lsp
local api = vim.api

local function get_text_at_range(range, position_encoding)
  return api.nvim_buf_get_text(
    0,
    range.start.line,
    lsp.util._get_line_byte_from_position(0, range.start, position_encoding),
    range["end"].line,
    lsp.util._get_line_byte_from_position(0, range["end"], position_encoding),
    {}
  )[1]
end

local function get_symbol_to_rename(cb)
  local cword = vim.fn.expand "<cword>"
  local clients = lsp.get_clients { bufnr = 0, method = "textDocument/rename" }

  if #clients == 0 then
    cb(cword)
    return
  end

  -- Prefer clients that support prepareRename
  table.sort(clients, function(a, b)
    return a:supports_method "textDocument/prepareRename" and not b:supports_method "textDocument/prepareRename"
  end)

  local client = clients[1]

  if client:supports_method "textDocument/prepareRename" then
    local params = lsp.util.make_position_params(0, client.offset_encoding)

    client:request("textDocument/prepareRename", params, function(err, result, _, _)
      if err or not result then
        cb(cword)
      end

      local symbol_text = cword

      if result.placeholder then
        symbol_text = result.placeholder
      elseif result.start then
        symbol_text = get_text_at_range(result, client.offset_encoding)
      elseif result.range then
        symbol_text = get_text_at_range(result.range, client.offset_encoding)
      end

      cb(symbol_text)
    end, 0)
  else
    cb(cword)
  end
end

return function()
  get_symbol_to_rename(function(to_rename)
    local buf = api.nvim_create_buf(false, true)

    local winopts = {
      height = 1,
      style = "minimal",
      border = "single",
      row = 1,
      col = 1,
      relative = "cursor",
      width = #to_rename + 15,
      title = { { " Renamer ", "@comment.danger" } },
      title_pos = "center",
    }

    local win = api.nvim_open_win(buf, true, winopts)
    vim.wo[win].winhl = "Normal:Normal,FloatBorder:Removed"
    api.nvim_set_current_win(win)

    api.nvim_buf_set_lines(buf, 0, -1, true, { " " .. to_rename })

    vim.bo[buf].buftype = "prompt"
    vim.fn.prompt_setprompt(buf, "")
    vim.api.nvim_input "A"

    vim.keymap.set({ "i", "n" }, "<Esc>", function()
      api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf })

    vim.fn.prompt_setcallback(buf, function(text)
      local newName = vim.trim(text)
      api.nvim_buf_delete(buf, { force = true })

      if #newName > 0 and newName ~= to_rename then
        local params = lsp.util.make_position_params(0, "utf-8")
        params = vim.tbl_extend("force", params, { newName = newName })
        lsp.buf_request(0, "textDocument/rename", params)
      end
    end)
  end)
end
