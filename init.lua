-- nvim-modern — a clean Lua + native-LSP starter config.
--
-- Launch it fully isolated from your existing ~/.config/nvim with:
--     NVIM_APPNAME=nvim-modern nvim
-- That makes Neovim read config from ~/.config/nvim-modern and keep its data,
-- state and plugins under ~/.local/{share,state}/nvim-modern — nothing here
-- ever touches your current setup.

-- Leader keys must be set BEFORE lazy.nvim / plugins load so mappings register
-- against the right leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')

-- Bootstrap lazy.nvim into the (isolated) data dir.
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
