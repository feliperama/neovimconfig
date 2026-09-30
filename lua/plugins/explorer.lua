-- File explorer: neo-tree (NERDTree replacement — sidebar, toggle, reveal).
return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    opts = function()
      local opts = {
        close_if_last_window = true,
        event_handlers = {
          {
            event = 'file_opened',
            handler = function()
              require('neo-tree.command').execute({ action = 'close' })
            end,
          },
        },
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          hijack_netrw_behavior = 'open_default',
        },
      }

      -- Without a Nerd Font (e.g. Monaco in Alacritty), Nerd Font glyphs render
      -- as boxes. When vim.g.have_nerd_font is false, fall back to markers any
      -- font can draw: plain Unicode for folders/files, letters for git status.
      -- Flip vim.g.have_nerd_font (in lua/config/options.lua) to get real icons.
      if not vim.g.have_nerd_font then
        opts.default_component_configs = {
          icon = {
            folder_closed = '▸',
            folder_open = '▾',
            folder_empty = '▸',
            -- Bypass nvim-web-devicons (Nerd Font glyphs) entirely.
            provider = function(icon, node)
              if node.type == 'directory' then
                icon.text = node:is_expanded() and '▾' or '▸'
              else
                icon.text = '·'
              end
            end,
          },
          git_status = {
            symbols = {
              added = 'A',
              modified = 'M',
              deleted = 'D',
              renamed = 'R',
              untracked = '?',
              ignored = 'I',
              unstaged = '✗',
              staged = '✓',
              conflict = '!',
            },
          },
        }
      end

      return opts
    end,
  },
}
