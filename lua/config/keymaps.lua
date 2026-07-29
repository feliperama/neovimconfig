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

-- <leader>w: toggle a color highlight on the word under the cursor (quickhl).
map('n', '<leader>w', util.toggle_word_highlight, { desc = 'Highlight word under cursor' })

--------------------------------------------------------------------------------
-- [FuzzyFinder]  ;   (fzf-lua)
--------------------------------------------------------------------------------
local ff = namespace('FuzzyFinder', ';')
ff('/', function() require('fzf-lua').blines() end, 'Lines in current file')
ff('f', function() require('fzf-lua').files() end, 'Find files')
ff('b', function() require('fzf-lua').buffers() end, 'Buffers')
ff('g', function() require('fzf-lua').live_grep() end, 'Grep in project')
ff('G', function()
  -- Project grep excluding test/spec files.
  require('fzf-lua').live_grep({
    rg_opts = "--column --line-number --no-heading --color=always --smart-case "
      .. "-g '!*.{test,spec}.*' -g '!**/__tests__/**' -g '!**/{test,tests,spec,__mocks__}/**'",
  })
end, 'Grep in project (no tests)')

--------------------------------------------------------------------------------
-- [Files]  f
--------------------------------------------------------------------------------
local f = namespace('Files', 'f')
f('y', util.copy_relative_path, 'Copy relative path + line')
f('Y', util.copy_absolute_path, 'Copy absolute path')
f('m', util.lsp_rename_file, 'Rename/move file (LSP)')
f('e', '<cmd>Neotree toggle<cr>', 'Toggle file explorer')
f('f', '<cmd>Neotree reveal<cr>', 'Reveal current file')

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
-- Minimal placeholder — wire up your tmux/vimux workflow here later.
--------------------------------------------------------------------------------
local term = namespace('Terminal', '!')
term('!', '<cmd>terminal<cr>', 'Open terminal')
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
