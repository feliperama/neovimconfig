local M = {}

function M.register()
  local pane = vim.env.TMUX_PANE
  local tmux = (vim.env.TMUX or ''):match('^(.*),%d+,%d+$')
  if not require('config.environment').is_standalone or not (pane and tmux) then
    return
  end

  local socket = vim.v.servername
  if socket:sub(1, 1) ~= '/' then
    socket = vim.fn.serverstart()
  end
  vim.system({ 'tmux', '-S', tmux, 'set-option', '-p', '-t', pane, '@nvim_socket', socket }, {}, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify('Could not register Neovim with tmux: ' .. vim.trim(result.stderr or ''), vim.log.levels.WARN)
      end)
    end
  end)
end

function M.open(path, line, column)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.fn.bufadd(path)
  vim.api.nvim_win_set_buf(win, buf)
  if line > 0 then
    line = math.min(line, vim.api.nvim_buf_line_count(buf))
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
    vim.api.nvim_win_set_cursor(win, { line, math.min(math.max(column - 1, 0), #text) })
  end
  return vim.api.nvim_win_get_buf(win) == buf
end

return M
