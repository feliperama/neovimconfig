-- Markdown reading + inline diagrams through Ghostty's Kitty graphics protocol.
return {
  {
    '3rd/image.nvim',
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
    ft = 'markdown',
    dependencies = { '3rd/image.nvim', 'nvim-treesitter/nvim-treesitter' },
    opts = function()
      return {
        integrations = { require('diagram.integrations.markdown') },
        events = {
          render_buffer = { 'BufWinEnter', 'InsertLeave', 'TextChanged' },
          clear_buffer = { 'BufLeave', 'InsertEnter' },
        },
        renderer_options = {
          mermaid = { theme = 'dark', background = 'transparent', scale = 2 },
        },
      }
    end,
    keys = {
      {
        '<leader>md',
        function() require('diagram').show_diagram_hover() end,
        ft = 'markdown',
        desc = 'View diagram in a tab',
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      latex = { enabled = false },
      html = { enabled = false },
      yaml = { enabled = false },
      code = { disable = { 'mermaid' } }, -- diagram.nvim owns these blocks
      win_options = {
        wrap = { default = false, rendered = true },
        linebreak = { default = false, rendered = true },
        breakindent = { default = false, rendered = true },
        colorcolumn = { default = '80,120', rendered = '' },
      },
    },
    keys = {
      { '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = 'Toggle Markdown rendering' },
    },
  },
}
