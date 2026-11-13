-- Markdown reading + inline diagrams through Ghostty's Kitty graphics protocol.
local environment = require('config.environment')

return {
  {
    '3rd/image.nvim',
    cond = environment.is_standalone,
    ft = 'markdown',
    build = false, -- use ImageMagick's CLI; no LuaRocks bindings needed
    config = function(_, opts) require('config.image').setup(opts) end,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
      max_width_window_percentage = 90,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      editor_only_render_when_focused = true,
      tmux_show_only_in_active_window = true,
      integrations = {
        markdown = { enabled = true, clear_in_insert_mode = true },
        neorg = { enabled = false },
        typst = { enabled = false },
        rst = { enabled = false },
        asciidoc = { enabled = false },
      },
    },
  },
  {
    '3rd/diagram.nvim',
    cond = environment.is_standalone,
    ft = 'markdown',
    dependencies = { '3rd/image.nvim', 'nvim-treesitter/nvim-treesitter' },
    config = function(_, opts) require('config.diagram').setup(opts) end,
    opts = function()
      return {
        integrations = { require('diagram.integrations.markdown') },
        events = {
          render_buffer = { 'BufWinEnter', 'InsertLeave', 'TextChanged' },
          clear_buffer = { 'BufLeave', 'InsertEnter' },
        },
        renderer_options = {
          mermaid = {
            theme = 'dark', background = 'transparent', scale = 2,
            config = { layout = 'elk' },
          },
        },
      }
    end,
    -- Keep lazy.nvim's filetype-scoped loading keys here, not in keymaps.lua.
    keys = {
      {
        '<leader>md',
        function() require('config.diagram').preview() end,
        ft = 'markdown',
        desc = 'View diagram in a tab',
      },
      { '<leader>mR', function() require('config.diagram').refresh() end, ft = 'markdown', desc = 'Refresh Mermaid diagram cache' },
      { '<leader>mo', function() require('config.diagram').open_svg() end, ft = 'markdown', desc = 'Open Mermaid SVG externally' },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    cond = environment.is_standalone,
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      latex = { enabled = false },
      html = { enabled = false },
      yaml = { enabled = false },
      code = { disable = { 'mermaid' } }, -- diagram.nvim owns these blocks
      -- Heavy perimeter, thin columns and body-row separators (display only).
      pipe_table = {
        border = { '┏', '┯', '┓', '┠', '┼', '┨', '┗', '┷', '┛', '│', '─' },
      },
      custom_handlers = {
        markdown = { parse = function(ctx) return require('config.markdown_tables').parse(ctx) end },
      },
      win_options = {
        wrap = { default = true, rendered = true },
        linebreak = { default = true, rendered = true },
        breakindent = { default = true, rendered = true },
        colorcolumn = { default = '80,120', rendered = '' },
      },
    },
    -- Keep lazy.nvim's filetype-scoped loading key with the plugin spec.
    keys = {
      { '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = 'Toggle Markdown rendering' },
    },
  },
}
