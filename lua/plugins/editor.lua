-- Editing niceties: motion, surround, autopairs, bookmarks.
-- (Commenting is native `gc`/`gcc` on 0.10+ — no plugin.)
return {
  -- Motion (easymotion replacement). `s` is taken by the [Windows] namespace,
  -- so the enhanced char motions (f/t/F/T) are disabled and jump is bound to
  -- <leader><leader> in keymaps.lua.
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = { char = { enabled = false } },
    },
  },

  -- Surround: cs"' , ds" , ysiw) , etc.
  { 'kylechui/nvim-surround', event = 'VeryLazy', opts = {} },

  -- Autopairs, integrated with blink.cmp.
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },

  -- Bookmarks (vim-bookmarks replacement). Own mappings only (mm/mn/mp/dm).
  { 'chentoast/marks.nvim', event = 'VeryLazy', opts = { default_mappings = false } },

  -- Seamless <C-hjkl> navigation between Neovim splits and tmux panes — the
  -- modern lua successor to christoomey/vim-tmux-navigator (also does resize,
  -- and supports wezterm/kitty/zellij). The tmux half already lives in
  -- ~/.tmux.conf (is_vim + `bind -n C-hjkl`) and is shared across configs.
  { 'mrjones2014/smart-splits.nvim', opts = {} },
}
