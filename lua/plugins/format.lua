-- Formatting (replaces coc-prettier + the per-filetype `formatprg` lines).
--
-- conform.nvim is the modern standalone formatter runner: it picks the formatter
-- by filetype, supports range formatting (so <leader>f works on a visual
-- selection), and falls back to the LSP when no external formatter is configured.
--
-- Prettier resolution matches what coc-prettier did: conform's built-in prettier
-- formatters look in the project's node_modules/.bin first, then $PATH. So each
-- repo formats with its own pinned prettier and its own .prettierrc, and files in
-- projects without prettier fall through to the LSP formatter instead.
--
-- The formatters are separate binaries, installed by mason-tool-installer below
-- (the non-LSP counterpart to mason-lspconfig's ensure_installed) so a fresh
-- clone ends up with a working <leader>f instead of a silent no-op.
return {
  {
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = 'ConformInfo', -- `:ConformInfo` shows what will run for this buffer
    opts = {
      -- prettierd is a long-lived daemon (much faster on repeat formats);
      -- stop_after_first falls back to plain prettier when it isn't installed.
      formatters_by_ft = {
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        vue = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        scss = { 'prettierd', 'prettier', stop_after_first = true },
        less = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        graphql = { 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
      },
      -- Filetypes with no entry above still format, via their language server.
      default_format_opts = { lsp_format = 'fallback' },
    },
  },

  -- Installs the formatter binaries, the way mason-lspconfig's ensure_installed
  -- installs the servers. check_install() is called directly instead of using
  -- run_on_start: that option is driven by a VimEnter autocmd registered in the
  -- plugin's plugin/ dir, which never fires for a lazy-loaded plugin (VimEnter
  -- is long gone by then) -- the tools would silently never install.
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    event = 'VeryLazy',
    config = function()
      require('mason-tool-installer').setup({
        -- prettierd is the global fallback; projects with their own prettier in
        -- node_modules keep using that one (conform prefers the local binary).
        ensure_installed = { 'stylua', 'prettierd' },
        run_on_start = false,
      })
      require('mason-tool-installer').check_install(false)
    end,
  },
}
