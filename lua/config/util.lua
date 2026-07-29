-- Small self-contained helpers used by keymaps.lua.
local M = {}

local function yank(text)
  vim.fn.setreg('+', text)
  vim.notify('Copied: ' .. text)
end

-- fy: relative path (to cwd) + current line number.
function M.copy_relative_path()
  local rel = vim.fn.expand('%')
  if rel == '' then
    return vim.notify('No file in this buffer', vim.log.levels.WARN)
  end
  yank(rel .. ':' .. vim.fn.line('.'))
end

-- fY: absolute path.
function M.copy_absolute_path()
  local abs = vim.fn.expand('%:p')
  if abs == '' then
    return vim.notify('No file in this buffer', vim.log.levels.WARN)
  end
  yank(abs)
end

-- <leader>w: quickhl-style toggle. Assign a persistent color to the word under
-- the cursor; press again on the same word to clear it. matchadd() is
-- window-local, which is fine for a starter.
local hl_groups = { 'ModernHL1', 'ModernHL2', 'ModernHL3', 'ModernHL4', 'ModernHL5', 'ModernHL6' }
local hl_colors = {
  ModernHL1 = '#e5c07b',
  ModernHL2 = '#98c379',
  ModernHL3 = '#e06c75',
  ModernHL4 = '#61afef',
  ModernHL5 = '#c678dd',
  ModernHL6 = '#56b6c2',
}
local active = {}   -- word -> match id
local next_color = 0

function M.setup_highlight_groups()
  for name, bg in pairs(hl_colors) do
    vim.api.nvim_set_hl(0, name, { bg = bg, fg = '#1e1e1e', bold = true })
  end
end

function M.toggle_word_highlight()
  local word = vim.fn.expand('<cword>')
  if word == '' then return end
  if active[word] then
    pcall(vim.fn.matchdelete, active[word])
    active[word] = nil
  else
    next_color = (next_color % #hl_groups) + 1
    active[word] = vim.fn.matchadd(hl_groups[next_color], '\\<' .. vim.fn.escape(word, '\\') .. '\\>')
  end
end

-- Visual-mode S: substitute the selected text across the file. The cmdline
-- opens as `:%s/<selection>//g` with the cursor parked in the empty replacement
-- slot -- the visual twin of <leader>saw (which uses the word under the cursor).
--
-- The pattern is prefixed with \V ("very nomagic") so the selection matches
-- literally: only `\` and the `/` delimiter stay special, and both are escaped
-- below. Without it, selecting something like `foo.bar()` would be read as a
-- regex and match the wrong things.
-- Used as the rhs of an <expr> mapping: returning the keys (rather than feeding
-- them with nvim_feedkeys) keeps it replayable inside a macro and equivalent to
-- <leader>saw's plain-string rhs.
function M.substitute_visual_selection()
  -- Read the selection while still in visual mode -- '< and '> aren't set yet.
  local lines = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = vim.fn.mode() })
  if #lines == 0 then return '<Esc>' end

  -- Escape each line first, then join: escaping after the join would mangle the
  -- `\n` separators into a literal backslash + n.
  for i, line in ipairs(lines) do
    lines[i] = (line:gsub('\\', '\\\\'):gsub('/', '\\/'))
  end
  local pattern = table.concat(lines, '\\n')

  -- <Esc> first: staying in visual mode would give `:'<,'>s/...`, scoping the
  -- substitute to the selection instead of the whole file.
  return '<Esc>:%s/\\V' .. pattern .. '//g<Left><Left>'
end

-- fm: rename / move the current file and let LSP fix up imports & references
-- via workspace/willRenameFiles + workspace/didRenameFiles (0.11+ APIs).
function M.lsp_rename_file()
  local buf = vim.api.nvim_get_current_buf()
  local old_path = vim.api.nvim_buf_get_name(buf)
  if old_path == '' then
    return vim.notify('No file to rename', vim.log.levels.WARN)
  end
  local old_rel = vim.fn.fnamemodify(old_path, ':.')

  vim.ui.input({ prompt = 'Rename/move to: ', default = old_rel, completion = 'file' }, function(input)
    if not input or input == '' or input == old_rel then return end
    local new_path = vim.fn.fnamemodify(input, ':p')
    local params = {
      files = { { oldUri = vim.uri_from_fname(old_path), newUri = vim.uri_from_fname(new_path) } },
    }
    local clients = vim.lsp.get_clients({ bufnr = buf })

    -- Ask servers what edits the rename implies, and apply them first.
    for _, client in ipairs(clients) do
      if client:supports_method('workspace/willRenameFiles') then
        local resp = client:request_sync('workspace/willRenameFiles', params, 1000, buf)
        if resp and resp.result then
          vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
        end
      end
    end

    -- Move the file on disk.
    vim.fn.mkdir(vim.fn.fnamemodify(new_path, ':h'), 'p')
    if vim.bo[buf].modified then vim.cmd('silent! write') end
    local ok, err = os.rename(old_path, new_path)
    if not ok then
      return vim.notify('Rename failed: ' .. tostring(err), vim.log.levels.ERROR)
    end

    -- Point the buffer at the new file.
    vim.api.nvim_buf_set_name(buf, new_path)
    vim.api.nvim_buf_call(buf, function() vim.cmd('silent! write!') end)

    -- Tell servers the rename happened.
    for _, client in ipairs(clients) do
      if client:supports_method('workspace/didRenameFiles') then
        client:notify('workspace/didRenameFiles', params)
      end
    end
    vim.notify('Renamed to ' .. vim.fn.fnamemodify(new_path, ':.'))
  end)
end

return M
