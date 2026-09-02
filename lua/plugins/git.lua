-- Git: keep vim-fugitive (you rely on it) and add gitsigns for hunk
-- signs / staging / navigation. Bindings live under [Git] in keymaps.lua.
return {
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G', 'Gvdiffsplit', 'Gdiffsplit', 'Gread', 'Gwrite', 'Gclog', 'Gedit' },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },
  {
    'AndrewRadev/linediff.vim',
    cmd = {
      'Linediff',
      'LinediffAdd',
      'LinediffLast',
      'LinediffShow',
      'LinediffReset',
      'LinediffMerge',
      'LinediffPick',
    },
  },
}
