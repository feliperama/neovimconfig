-- Mermaid CLI 11 includes ELK. Keep PNGs inline and generate SVGs for external
-- viewing. Own the cache key because diagram.nvim only hashes the source text.
local M = {}
local options = {}
local pending = {}
local cache = vim.fn.stdpath('cache') .. '/diagram-cache/mermaid-local'
local executable = vim.fn.stdpath('data') .. '/mermaid-cli/node_modules/.bin/mmdc'

local function paths(source, opts)
  local key = vim.fn.sha256(source .. vim.inspect(opts) .. executable .. ':11.12.0:v1')
  return cache .. '/' .. key
end

-- Return diagram.nvim's job descriptor; optional callback is also used by the
-- preview. Concurrent requests for the same image share one browser process.
function M.render(source, opts, format, callback)
  format = format or 'png'
  local base = paths(source, opts)
  local path = base .. '.' .. format
  if pending[path] then
    if callback then table.insert(pending[path].callbacks, callback) end
    return { file_path = path, job_id = pending[path].job }
  end
  if vim.fn.filereadable(path) == 1 then
    if callback then vim.schedule(function() callback(path) end) end
    return { file_path = path }
  end
  if vim.fn.executable(executable) ~= 1 then
    vim.notify('Install Neovim\'s Mermaid CLI: see README.md', vim.log.levels.ERROR)
    return { file_path = path }
  end

  vim.fn.mkdir(cache, 'p')
  -- PNG and SVG jobs may run together (pressing o while the tab is loading).
  local input, config = path .. '.mmd', path .. '.json'
  vim.fn.writefile(vim.split(source, '\n', { plain = true }), input)
  vim.fn.writefile({ vim.json.encode(opts.config or {}) }, config)
  -- A dark background makes SVG labels readable in light-themed system viewers.
  local background = format == 'svg' and '#181818' or (opts.background or 'transparent')
  local args = {
    executable, '-i', input, '-o', path, '-c', config,
    '-t', opts.theme or 'dark', '-b', background, '-s', tostring(opts.scale or 2),
  }
  local work = { callbacks = callback and { callback } or {} }
  pending[path] = work
  local errors = {}
  work.job = vim.fn.jobstart(args, {
    stderr_buffered = true,
    on_stderr = function(_, data) errors = data end,
    on_exit = function(_, code)
      pending[path] = nil
      vim.fn.delete(input)
      vim.fn.delete(config)
      if code ~= 0 or vim.fn.filereadable(path) ~= 1 then
        vim.fn.delete(path) -- never reuse partial/failed output
        vim.notify('Mermaid rendering failed:\n' .. table.concat(errors, '\n'), vim.log.levels.ERROR)
        return
      end
      for _, done in ipairs(work.callbacks) do done(path) end
    end,
  })
  if work.job <= 0 then
    pending[path] = nil
    vim.fn.delete(input)
    vim.fn.delete(config)
    vim.notify('Unable to start Mermaid CLI', vim.log.levels.ERROR)
    return { file_path = path }
  end
  return { file_path = path, job_id = work.job }
end

-- Use the fenced node's full range, including either backtick or tilde fences.
function M.at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= 'markdown' then return end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local parser = vim.treesitter.get_parser(buf, 'markdown')
  local query = vim.treesitter.query.parse('markdown', '(fenced_code_block) @block')
  for _, node in query:iter_captures(parser:parse()[1]:root(), buf) do
    local first, _, last = node:range()
    if row >= first and row < last then
      local language, source
      for child in node:iter_children() do
        if child:type() == 'info_string' then language = vim.treesitter.get_node_text(child, buf) end
        if child:type() == 'code_fence_content' then source = vim.treesitter.get_node_text(child, buf) end
      end
      if language == 'mermaid' and source then return source end
    end
  end
end

function M.open_svg(source)
  source = source or M.at_cursor()
  if not source then return vim.notify('Place the cursor inside a Mermaid block') end
  M.render(source, options, 'svg', function(path)
    local _, err = vim.ui.open(path)
    if err then vim.notify(tostring(err), vim.log.levels.ERROR) end
  end)
end

function M.refresh()
  local source = M.at_cursor()
  if not source then return vim.notify('Place the cursor inside a Mermaid block') end
  local base = paths(source, options)
  if pending[base .. '.png'] or pending[base .. '.svg'] then
    return vim.notify('This diagram is still rendering; try refresh when it finishes')
  end
  for _, format in ipairs({ 'png', 'svg' }) do vim.fn.delete(base .. '.' .. format) end
  require('image/utils/transform_cache').clear_for_path(base .. '.png')
  for _, image in ipairs(require('image').get_images()) do
    if image.original_path == base .. '.png' then image:clear() end
  end
  -- Refresh only while the originating buffer is still visible and unchanged.
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  M.render(source, options, 'png', function()
    if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_current_win() == win
      and vim.api.nvim_buf_get_changedtick(buf) == tick then
      require('diagram').render()
    end
    vim.notify('Mermaid cache refreshed')
  end)
end

function M.preview()
  local source = M.at_cursor()
  if not source then return require('diagram').show_diagram_hover() end
  -- Open the tab immediately so a late browser result cannot steal focus.
  vim.cmd.tabnew()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '# Mermaid diagram', '', 'q / Esc: close    o: open external SVG', '', 'Rendering…',
  })
  vim.bo[buf].modifiable = false
  local image
  local function clear()
    if image then image:clear() end
  end
  local function close()
    clear()
    vim.cmd.tabclose()
  end
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, close, { buffer = buf, desc = 'Close diagram tab' })
  end
  vim.keymap.set('n', 'o', function() M.open_svg(source) end,
    { buffer = buf, desc = 'Open diagram as SVG' })
  vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWipeout' }, { buffer = buf, callback = clear })
  vim.api.nvim_create_autocmd('BufEnter', { buffer = buf, callback = function()
    if image then image:render() end
  end })
  M.render(source, options, 'png', function(path)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 4, 5, false, { '' })
    vim.bo[buf].modifiable = false
    image = require('image').from_file(path, {
      buffer = buf, window = win, with_virtual_padding = true, inline = true, x = 0, y = 4,
    })
    if image and vim.api.nvim_get_current_buf() == buf then image:render() end
  end)
end

function M.setup(opts)
  options = opts.renderer_options.mermaid
  require('diagram/renderers/mermaid').render = function(source, renderer_opts)
    return M.render(source, renderer_opts)
  end
  require('diagram').setup(opts)
end

return M
