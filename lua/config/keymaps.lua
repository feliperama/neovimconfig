-- All key bindings live here.
--
-- Namespace-prefix pattern (ported from the vim-plug config): a single key is
-- turned into a readable, named "namespace" so bindings stay self-documenting:
--     local f = namespace('Files', 'f')
--     f('y', ..., 'Copy relative path')   -- maps `fy`
--
-- The old config used the `nnoremap [Files] <Nop>` + `nmap f [Files]` pseudo-key
-- trick. That indirection conflicts with which-key (which claims the bare prefix
-- key for its own popup and can't see children hidden behind the pseudo-key), so
-- here the helper maps the real keys directly — same named, grouped structure,
-- but which-key can now both label the group AND list its children.

local util = require('config.util')
local map = vim.keymap.set

-- Declare a named namespace bound to `key`, returning a helper that hangs
-- children off it. `sub('/', rhs, 'desc')` maps `<prefix>/`.
local function namespace(name, key)
  return function(suffix, rhs, desc)
    map('n', key .. suffix, rhs, { desc = name .. ': ' .. desc, silent = true })
  end
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- q quits the window (overrides native "start recording"); <leader>q takes over
-- macro recording. <leader>q -> q must be non-recursive (the default) so it
-- reaches the native q, not this :quit mapping.
map('n', 'q', '<cmd>quit<cr>', { desc = 'Quit window' })
map('n', '<leader>q', 'q', { desc = 'Record macro (native q)' })

-- <leader>saw: substitute the word under the cursor across the file. Lands the
-- cursor in the (empty) replacement slot, ready to type.
map('n', '<leader>saw', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]], { desc = 'Substitute word in file' })

-- S (visual): same idea for an arbitrary selection instead of the cursor word.
-- Takes over from nvim-surround's visual mapping, which moves to `gs` (see
-- plugins/editor.lua).
map('x', 'S', util.substitute_visual_selection, {
  expr = true,
  replace_keycodes = true,
  desc = 'Substitute selection in file',
})

-- `ae` — "the entire file" text object (replaces kana/vim-textobj-entire, which
-- needed vim-textobj-user as a dependency; a two-line mapping does the same job).
-- Works with any operator: vae selects the file, yae copies it, =ae reindents it.
-- The :normal! makes a linewise visual selection over the whole buffer, which
-- the pending operator then applies to.
map({ 'x', 'o' }, 'ae', ':<C-u>normal! ggVG<cr>', { silent = true, desc = 'Text object: entire file' })

-- <leader>f: format. Whole buffer in normal mode, just the selection in visual
-- mode (conform.nvim works out the range) — the coc-format / coc-format-selected
-- pair from the old config, collapsed into one key.
map({ 'n', 'x' }, '<leader>f', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer or selection' })

-- <leader>w: toggle a color highlight on the word under the cursor (quickhl).
map('n', '<leader>w', util.toggle_word_highlight, { desc = 'Highlight word under cursor' })

-- Fold the whole window at the selected depth. 1 closes every fold, while
-- each higher number leaves one more outer level open; 0 opens everything.
map('n', '<leader>0', function() vim.wo.foldlevel = 99 end, { desc = 'Folds: open all' })
for key = 1, 9 do
  local level = key - 1
  map('n', '<leader>' .. key, function() vim.wo.foldlevel = level end, {
    desc = 'Folds: close level ' .. key,
  })
end

map('n', '<CR>', function()
  -- gr uses quickfix: Enter should jump and close the list, not toggle folds.
  if vim.bo.buftype == 'quickfix' then
    local is_location_list = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1
    return '<CR><Cmd>' .. (is_location_list and 'lclose' or 'cclose') .. '<CR>'
  end

  -- Keep native Enter in terminal and other special buffers.
  if vim.bo.buftype ~= '' then
    return '<CR>'
  end

  if vim.fn.foldclosed('.') ~= -1 then
    return 'zo'
  elseif vim.fn.foldlevel('.') > 0 then
    return 'zc'
  end

  return '<CR>'
end, { expr = true, remap = false, desc = 'Toggle innermost fold, otherwise native Enter' })

--------------------------------------------------------------------------------
-- [FuzzyFinder]  ;   (fzf-lua)
--------------------------------------------------------------------------------
local ff = namespace('FuzzyFinder', ';')
ff('/', function() require('fzf-lua').blines() end, 'Lines in current file')
ff('f', function() require('fzf-lua').files() end, 'Find files')
ff('b', function() require('fzf-lua').buffers() end, 'Buffers')
-- Feed project lines to fzf for fuzzy matching; live_grep uses rg regex matching.
-- Keep bulk data out of the fuzzy candidate set. Use ;r to search larger/data files.
local project_rg_opts = '--hidden --column --line-number --no-heading --color=always --smart-case '
  .. "--max-columns=4096 -g '!.git'"
local fuzzy_rg_opts = project_rg_opts
  .. " --max-filesize=1M -g '!*.csv' -g '!package-lock.json' -g '!npm-shrinkwrap.json'"
  .. " -g '!yarn.lock' -g '!pnpm-lock.yaml' -g '!bun.lock' -g '!bun.lockb'"
ff('g', function()
  require('fzf-lua').grep_project({
    rg_opts = fuzzy_rg_opts .. ' -e',
  })
end, 'Fuzzy search project lines')
ff('G', function()
  -- Project grep excluding test/spec files.
  require('fzf-lua').grep_project({
    rg_opts = fuzzy_rg_opts
      .. " -g '!*.{test,spec}.*' -g '!**/__tests__/**' -g '!**/{test,tests,spec,__mocks__}/**' -e",
  })
end, 'Fuzzy search project lines (no tests)')
ff('r', function()
  -- Ripgrep narrows results before loading them; Ctrl-g then fuzzy-filters them.
  require('fzf-lua').live_grep({ rg_opts = project_rg_opts .. ' -e' })
end, 'Live grep project (include data and large files)')

--------------------------------------------------------------------------------
-- [Files]  f
--------------------------------------------------------------------------------
local f = namespace('Files', 'f')
f('y', util.copy_relative_path, 'Copy relative path + line')
f('Y', util.copy_absolute_path, 'Copy absolute path + line')
f('m', util.lsp_rename_file, 'Rename/move file (LSP)')
f('e', '<cmd>Neotree toggle<cr>', 'Toggle file explorer')
f('f', function()
  require('neo-tree.command').execute({
    source = 'filesystem',
    action = 'focus',
    reveal_file = vim.api.nvim_buf_get_name(0),
    reveal_force_cwd = true,
  })
end, 'Reveal current file')

--------------------------------------------------------------------------------
-- [Windows]  s
--------------------------------------------------------------------------------
local s = namespace('Windows', 's')
s('v', '<cmd>split<cr>', 'Split horizontal')
s('g', '<cmd>vsplit<cr>', 'Split vertical')
s('c', '<cmd>close<cr>', 'Close window')
s('o', '<cmd>only<cr>', 'Close other windows')
s('b', '<cmd>buffer #<cr>', 'Previous (alternate) buffer')
s('s', '<C-w>R', 'Swap pane positions')
s('h', '<C-w>h', 'Go to left window')
s('j', '<C-w>j', 'Go to lower window')
s('k', '<C-w>k', 'Go to upper window')
s('l', '<C-w>l', 'Go to right window')

map('n', '<Up>', '<cmd>resize -2<cr>', { desc = 'Decrease window height', silent = true })
map('n', '<Down>', '<cmd>resize +2<cr>', { desc = 'Increase window height', silent = true })
map('n', '<Left>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width', silent = true })
map('n', '<Right>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width', silent = true })

--------------------------------------------------------------------------------
-- [Tabs]  t
--------------------------------------------------------------------------------
local t = namespace('Tabs', 't')
t('t', '<cmd>tabnew<cr>', 'New tab')
t('c', '<cmd>tabclose<cr>', 'Close tab')
t('l', '<cmd>tabnext<cr>', 'Next tab')
t('h', '<cmd>tabprevious<cr>', 'Previous tab')
t('o', '<cmd>tabonly<cr>', 'Close other tabs')

--------------------------------------------------------------------------------
-- [Terminal]  !
-- !! prompts for a command, then opens or reuses a right-hand tmux pane (the
-- same shape as prefix-g in ~/.tmux.conf). The command is sent to interactive
-- zsh, so it stays visible; submitting an empty prompt just opens/focuses zsh.
--------------------------------------------------------------------------------
local term = namespace('Terminal', '!')
local terminal_pane_id

term('!', function()
  local nvim_width_ratio = 2 / 3
  local command = vim.fn.input('!!')
  vim.cmd('redraw')

  if not vim.env.TMUX or vim.env.TMUX == '' then
    vim.notify('!! requires Neovim to be running inside tmux', vim.log.levels.ERROR)
    return
  end

  if terminal_pane_id then
    local existing_pane_id = vim.fn.system({
      'tmux',
      'display-message',
      '-p',
      '-t',
      terminal_pane_id,
      '#{pane_id}',
    })
    if vim.v.shell_error ~= 0 or vim.trim(existing_pane_id) ~= terminal_pane_id then terminal_pane_id = nil end
  end

  if terminal_pane_id then
    vim.fn.system({ 'tmux', 'select-pane', '-t', terminal_pane_id })
    if vim.v.shell_error ~= 0 then terminal_pane_id = nil end
  end

  if not terminal_pane_id then
    local terminal_width_percent = math.floor((1 - nvim_width_ratio) * 100)
    local output = vim.fn.system({
      'tmux',
      'split-window',
      '-P',
      '-F',
      '#{pane_id}',
      '-h',
      '-p',
      tostring(terminal_width_percent),
      '-c',
      vim.fn.getcwd(),
    })

    if vim.v.shell_error ~= 0 then
      vim.notify('Could not create tmux pane: ' .. vim.trim(output), vim.log.levels.ERROR)
      return
    end

    terminal_pane_id = vim.trim(output)
    if not terminal_pane_id:match('^%%%d+$') then
      vim.notify('tmux returned an invalid pane ID: ' .. terminal_pane_id, vim.log.levels.ERROR)
      terminal_pane_id = nil
      return
    end
  end

  if command ~= '' then
    -- Type into the interactive shell instead of using `zsh -c`, so the command
    -- remains visible at the prompt and the same pane can accept later commands.
    vim.fn.system({ 'tmux', 'send-keys', '-t', terminal_pane_id, '-l', command })
    vim.fn.system({ 'tmux', 'send-keys', '-t', terminal_pane_id, 'Enter' })
  end
end, 'Run command in reusable tmux pane')

term('s', '<cmd>split | terminal<cr>', 'Terminal in horizontal split')
term('v', '<cmd>vsplit | terminal<cr>', 'Terminal in vertical split')
map('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'Terminal: exit to normal mode' })

--------------------------------------------------------------------------------
-- [Git]  <leader>g   (fugitive + gitsigns)
-- Bare `g` can't be a namespace here without shadowing gg/gd/gy/gi/gr and the
-- native `gc` comment op, so Git hangs off <leader>g instead.
--------------------------------------------------------------------------------
local g = namespace('Git', '<leader>g')
g('s', '<cmd>Git<cr>', 'Status (fugitive)')
g('b', '<cmd>Git blame<cr>', 'Blame')
g('d', '<cmd>Gvdiffsplit<cr>', 'Diff split')
g('l', '<cmd>Git log<cr>', 'Log')
g('p', function() require('gitsigns').preview_hunk() end, 'Preview hunk')
g('S', function() require('gitsigns').stage_hunk() end, 'Stage hunk')
g('R', function() require('gitsigns').reset_hunk() end, 'Reset hunk')
map('x', '<leader>gD', ":'<,'>Linediff<cr>", { desc = 'Diff selected lines' })
map('x', '<leader>gR', '<cmd>LinediffReset<cr>', { desc = 'Reset line diff' })
map('n', ']h', function() require('gitsigns').nav_hunk('next') end, { desc = 'Next git hunk' })
map('n', '[h', function() require('gitsigns').nav_hunk('prev') end, { desc = 'Prev git hunk' })

--------------------------------------------------------------------------------
-- Bookmarks (marks.nvim)  mm / mn / mp / dm
--------------------------------------------------------------------------------
map('n', 'mm', function() require('marks').toggle_bookmark0() end, { desc = 'Toggle bookmark' })
map('n', 'mn', function() require('marks').next_bookmark0() end, { desc = 'Next bookmark' })
map('n', 'mp', function() require('marks').prev_bookmark0() end, { desc = 'Prev bookmark' })
map('n', 'dm', function() require('marks').delete_bookmark0() end, { desc = 'Clear bookmarks' })

--------------------------------------------------------------------------------
-- Split <-> tmux pane navigation (smart-splits).
-- <C-hjkl> moves to the adjacent Neovim split, or hands off to the adjacent
-- tmux pane when there's no split in that direction. The tmux side (is_vim +
-- `bind -n C-hjkl`) lives in ~/.tmux.conf and is shared across configs.
--------------------------------------------------------------------------------
map('n', '<C-h>', function() require('smart-splits').move_cursor_left() end, { desc = 'Nav split/pane left' })
map('n', '<C-j>', function() require('smart-splits').move_cursor_down() end, { desc = 'Nav split/pane down' })
map('n', '<C-k>', function() require('smart-splits').move_cursor_up() end, { desc = 'Nav split/pane up' })
map('n', '<C-l>', function() require('smart-splits').move_cursor_right() end, { desc = 'Nav split/pane right' })

--------------------------------------------------------------------------------
-- Motion (flash.nvim) — easymotion replacement.
-- `s` is taken by [Windows], so jump lives on <leader><leader>.
--------------------------------------------------------------------------------
map({ 'n', 'x', 'o' }, '<leader><leader>', function() require('flash').jump() end, { desc = 'Flash jump' })
map({ 'n', 'x', 'o' }, '<leader>S', function() require('flash').treesitter() end, { desc = 'Flash treesitter' })

-- `/` takes over from native search with a 2-char, cross-window jump — the
-- flash equivalent of the old <Plug>(easymotion-overwin-f2). `max_length = 2`
-- makes flash stop reading the pattern after two characters and show labels;
-- `multi_window` (flash default) is what made easymotion's "overwin" variant
-- able to land in another split.
--
-- Normal mode only, so visual/operator-pending `/` (e.g. `d/foo`) and `?` keep
-- the native search. `<leader>/` is the escape hatch for a real regex search
-- (with history and n/N); `;/` fuzzy-searches the buffer via fzf-lua.
map('n', '/', function()
  require('flash').jump({ search = { max_length = 2 } })
end, { desc = 'Flash jump (2 chars, cross-window)' })
map('n', '<leader>/', '/', { desc = 'Native search' })

--------------------------------------------------------------------------------
-- LSP — buffer-local, attached only when a server is running for the buffer.
-- Native `gc`/`gcc` commenting is built in; no mapping needed.
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('modern-lsp-attach', { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local function lmap(lhs, rhs, desc)
      map('n', lhs, rhs, { buffer = buf, desc = 'LSP: ' .. desc, silent = true })
    end
    lmap('gd', vim.lsp.buf.definition, 'Definition')
    lmap('gy', vim.lsp.buf.type_definition, 'Type definition')
    lmap('gi', vim.lsp.buf.implementation, 'Implementation')
    lmap('gr', vim.lsp.buf.references, 'References')
    lmap('K', vim.lsp.buf.hover, 'Hover docs')
    lmap('<leader>r', vim.lsp.buf.rename, 'Rename symbol')
    lmap('<leader>A', vim.lsp.buf.code_action, 'Code action')
    lmap('<leader>e', vim.diagnostic.open_float, 'Line diagnostics')
    lmap('<leader>F', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
    lmap(']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next diagnostic')
    lmap('[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Prev diagnostic')
  end,
})

-- Colors for the quickhl word highlighter, re-applied across colorscheme swaps.
util.setup_highlight_groups()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('modern-hl', { clear = true }),
  callback = util.setup_highlight_groups,
})
