-- UI: colorscheme, statusline (airline replacement), which-key group labels.
return {
  {
    'rakr/vim-one',
    lazy = false,
    priority = 1000, -- load colorscheme before other UI plugins
    config = function()
      -- Base ---------------------------------------------------------------
      vim.g.one_allow_italics = 1 -- italic comments/keywords
      vim.o.background = 'dark'    -- switch to 'light' for the light variant

      -- Custom highlight overrides -----------------------------------------
      -- Re-applied on every :colorscheme so they survive scheme reloads.
      local function overrides()
        local hl = vim.api.nvim_set_hl
        -- Editor background: transparent (terminal bg shows through), matching
        -- the "last one wins" guibg=none from the old config. For a SOLID
        -- background instead, set bg = '#303034' here.
        hl(0, 'Normal', { fg = '#abb2bf', bg = 'NONE' })
        -- 80/120 column guides.
        hl(0, 'ColorColumn', { bg = '#2d2d30' })
        -- Split divider lines (near-black). Neovim uses WinSeparator;
        -- VertSplit is the old name, kept for safety.
        hl(0, 'WinSeparator', { fg = '#000000', bg = '#000000' })
        hl(0, 'VertSplit', { fg = '#141414', bg = '#141414' })
        -- Tabline.
        hl(0, 'TabLineSel', { fg = '#FFFFFF', bg = '#303034' })
        hl(0, 'TabLine', { fg = '#676a70', bg = '#47474c' })
        hl(0, 'TabLineFill', { bg = '#303034' })
        -- Insert-mode cursor: white vertical bar (see guicursor below).
        hl(0, 'iCursor', { fg = 'white', bg = 'white' })
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('modern-theme-overrides', { clear = true }),
        callback = overrides,
      })

      -- Editor guides + cursor ---------------------------------------------
      vim.opt.colorcolumn = '80,120'
      vim.opt.guicursor:append('i-ci-ve:ver25-iCursor')

      -- Apply the scheme (this fires the ColorScheme autocmd -> overrides()).
      vim.cmd.colorscheme('one')
    end,
  },

  -- Statusline (replaces vim-airline).
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = function()
      -- Minimalist theme ported from the old vim-airline 'minimalist'. airline's
      -- N1/N2/N3 map directly to lualine's a/b/c sections:
      --   N1 (mode)     fg #E4E4E4 / bg #3A3A3A  -> a
      --   N2 (branch)   fg #E4E4E4 / bg #4E4E4E  -> b
      --   N3 (filename) fg #EEEEEE / bg #262626  -> c  (the big middle bar)
      local minimalist = {
        normal = {
          a = { fg = '#E4E4E4', bg = '#3A3A3A' },
          b = { fg = '#E4E4E4', bg = '#4E4E4E' },
          c = { fg = '#EEEEEE', bg = '#262626' },
        },
        inactive = {
          a = { fg = '#676a70', bg = '#262626' },
          b = { fg = '#676a70', bg = '#262626' },
          c = { fg = '#676a70', bg = '#262626' },
        },
      }
      -- Uniform across modes (that's what makes it "minimalist").
      minimalist.insert = minimalist.normal
      minimalist.visual = minimalist.normal
      minimalist.replace = minimalist.normal
      minimalist.command = minimalist.normal

      return {
        options = {
          theme = minimalist,
          globalstatus = false, -- per-window statusline (laststatus=2)
          section_separators = '',
          component_separators = '|',
        },
      }
    end,
  },

  -- which-key: labels the namespace prefixes. The named-prefix structure itself
  -- (the [Files]/[Windows]/... pseudo-keys) is defined in keymaps.lua; here we
  -- only attach human-readable group names to the keys that open them.
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      wk.add({
        { ';', group = 'FuzzyFinder' },
        { 'f', group = 'Files' },
        { 's', group = 'Windows' },
        { 't', group = 'Tabs' },
        { '!', group = 'Terminal' },
        { 'm', group = 'Bookmarks' },
        { '<leader>g', group = 'Git' },
      })
    end,
  },
}
