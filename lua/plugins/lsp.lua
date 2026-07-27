-- LSP + completion + snippets.
-- Uses the 0.11+ native API: vim.lsp.config() / vim.lsp.enable(), driven by
-- mason (server install) + mason-lspconfig (auto-enable) + nvim-lspconfig
-- (ships the per-server default configs).

return {
  -- Completion engine: blink.cmp. Fast, batteries-included, uses the native
  -- vim.snippet API, and ships prebuilt binaries (no cargo build needed).
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      -- super-tab: <Tab>/<S-Tab> select & accept, jump snippet placeholders —
      -- closest to the coc.nvim muscle memory you're migrating from.
      keymap = { preset = 'super-tab' },
      appearance = { nerd_font_variant = 'mono' },
      sources = { default = { 'lsp', 'snippets', 'path', 'buffer' } },
      snippets = { preset = 'default' },
      signature = { enabled = true },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 } },
    },
  },

  -- Neovim Lua development: makes lua_ls aware of the nvim runtime & plugins.
  { 'folke/lazydev.nvim', ft = 'lua', opts = {} },

  -- Server installer. `:Mason` opens the UI.
  { 'mason-org/mason.nvim', cmd = 'Mason', opts = {} },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      -- Give every server blink's completion capabilities.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- lua_ls: lazydev supplies the nvim runtime library; just quiet the rest.
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      require('mason').setup()
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'ts_ls' },
        automatic_enable = true, -- vim.lsp.enable() each installed server
      })
    end,
  },
}
