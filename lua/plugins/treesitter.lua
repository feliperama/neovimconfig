-- Treesitter (main branch — the modern rewrite for 0.11+).
-- Highlighting is started per-buffer via the native vim.treesitter.start().
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'typescript', 'tsx', 'javascript', 'lua', 'json',
        'vimdoc', 'markdown', 'markdown_inline', 'bash',
      })

      -- The `tsx` parser also drives .tsx / typescriptreact buffers.
      vim.treesitter.language.register('tsx', 'typescriptreact')

      -- Turn on treesitter highlighting for any buffer whose language has a
      -- parser installed. No-ops cleanly for languages without one.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('modern-treesitter', { clear = true }),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
