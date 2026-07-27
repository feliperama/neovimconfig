-- A clean Lua + native-LSP Neovim config. See README.md for install.
-- Clone into ~/.config/nvim and run `nvim`; everything bootstraps on first launch.

-- Leader keys must be set BEFORE lazy.nvim / plugins load so mappings register
-- against the right leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')

-- Bootstrap lazy.nvim into the data dir.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error('Failed to clone lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Every file under lua/plugins/ returns a plugin spec; lazy imports them all.
require('lazy').setup({
  spec = { { import = 'plugins' } },
  install = { colorscheme = { 'one', 'habamax' } },
  checker = { enabled = false },        -- don't auto-check for plugin updates
  change_detection = { notify = false },
})

require('config.keymaps')
