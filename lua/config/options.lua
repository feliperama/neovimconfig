-- Editor options. Kept small and opinionated; tweak freely.

local o = vim.opt

-- UI
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'          -- avoid text shifting when diagnostics/git signs appear
o.cursorline = true
o.termguicolors = true
o.scrolloff = 6
o.wrap = false
o.winborder = 'rounded'       -- 0.11+: global default border for floating windows

-- Splits (matches the `sv`/`sg` window bindings — new splits open right/below)
o.splitright = true
o.splitbelow = true

-- Search
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true

-- Indentation (2 spaces; ts/js/lua all use it here)
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true

-- Behaviour
o.mouse = 'a'
o.clipboard = 'unnamedplus'   -- yank/paste through the system clipboard
o.undofile = true             -- persistent undo across sessions
o.updatetime = 250
o.timeoutlen = 400
o.completeopt = { 'menu', 'menuone', 'noselect' }
o.confirm = true              -- prompt to save instead of failing on :q with changes

-- Diagnostics presentation (native vim.diagnostic)
vim.diagnostic.config({
  virtual_text = { prefix = '●' },
  severity_sort = true,
  float = { border = 'rounded', source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
  },
})
