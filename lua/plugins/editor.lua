-- Editing niceties: motion, surround, autopairs, bookmarks.
-- (Commenting is native `gc`/`gcc` on 0.10+ — no plugin.)
return {
  -- Motion (easymotion replacement). `s` is taken by the [Windows] namespace,
  -- so the enhanced char motions (f/t/F/T) are disabled; jump is bound to
  -- <leader><leader> and to `/` (2-char, easymotion-overwin-f2 style) in
  -- keymaps.lua.
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = { char = { enabled = false } },
    },
  },

  -- Surround: cs"' , ds" , ysiw) , etc.
  -- Visual-mode surround moves off `S` (the default) to `gs`, because `S` is
  -- bound to "substitute the selection" in keymaps.lua.
  --
  -- As of nvim-surround v4, setup() no longer accepts a `keymaps` table -- the
  -- defaults are plain mappings created when the plugin loads, so they're
  -- retargeted by disabling the visual ones and binding the <Plug> mappings by
  -- hand. `init` (not `config`) sets the flag, since it has to land before the
  -- plugin's own mappings are created.
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    init = function()
      vim.g.nvim_surround_no_visual_mappings = true
    end,
    config = function()
      -- gS (linewise) is re-bound to the same key it defaults to, so that
      -- disabling the visual defaults doesn't quietly drop it.
      vim.keymap.set('x', 'gs', '<Plug>(nvim-surround-visual)', { desc = 'Surround selection' })
      vim.keymap.set('x', 'gS', '<Plug>(nvim-surround-visual-line)', { desc = 'Surround selection, on new lines' })
    end,
  },

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
