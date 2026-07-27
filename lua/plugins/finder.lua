-- Fuzzy finder: fzf-lua.
-- Closest to your existing fzf.vim workflow (same fzf binary underneath) and
-- the fastest picker for large-project grep. Bindings live in keymaps.lua.
return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      winopts = { height = 0.85, width = 0.85, preview = { layout = 'vertical' } },
    },
  },
}
