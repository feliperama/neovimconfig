# neovimconfig

A clean, minimal Neovim **0.12** config: Lua + native LSP.

## Prerequisites

Install these **before** first launch. On macOS with Homebrew (`git` and a C compiler come
with the Xcode Command Line Tools — `xcode-select --install`):

```sh
brew install neovim node fzf ripgrep fd tree-sitter-cli
```

| Tool | Why it's needed |
|---|---|
| **Neovim ≥ 0.11** | tested on 0.12.4 (uses `vim.lsp.config`/`enable`, `winborder`, …) |
| **C compiler** (`cc`) | compiles Treesitter parsers |
| **`tree-sitter` CLI** | nvim-treesitter's *main* branch builds parsers with it — **without it, highlighting won't compile** |
| **`node`** | runs the TypeScript/JavaScript language server |
| **`fzf`, `ripgrep`, `fd`** | the fuzzy finder (files / grep) |

## Installation

Clone into your Neovim config directory and launch:

```sh
git clone https://github.com/feliperama/neovimconfig ~/.config/nvim
nvim
```

> If `~/.config/nvim` already exists, move it aside first (`mv ~/.config/nvim ~/.config/nvim.bak`).

## First launch — what happens automatically

Everything bootstraps on the first `nvim`; give it a minute and stay connected to the
network:

1. **lazy.nvim** self-installs, then installs every plugin at the versions pinned in
   `lazy-lock.json`. `blink.cmp` downloads its prebuilt completion binary (only needs Rust
   if no prebuilt exists for your platform).
2. **Treesitter parsers** (`typescript`, `tsx`, `javascript`, `lua`, `json`, …) compile via
   the `tree-sitter` CLI. If the first file's highlighting looks plain, restart `nvim` once
   the parsers finish (or run `:TSUpdate`).
3. **LSP servers** (`lua_ls`, `typescript-language-server`) install the first time you open
   a Lua/TS/JS file (via `mason-lspconfig`'s `ensure_installed`).
4. Check status any time: **`:Lazy`** (plugins), **`:Mason`** (LSP servers),
   **`:checkhealth`** (diagnostics). If anything looks incomplete, run **`:Lazy sync`**.

## File layout

```
init.lua                  entry: leader, options, lazy bootstrap, module requires
lua/config/options.lua    editor settings
lua/config/keymaps.lua    all key bindings (namespace prefixes + LSP + motion + git …)
lua/config/util.lua       helpers (copy path, quickhl, LSP rename-file, substitute)
lua/plugins/lsp.lua       mason + lspconfig + blink.cmp + lazydev
lua/plugins/treesitter.lua
lua/plugins/finder.lua    fzf-lua
lua/plugins/explorer.lua  neo-tree
lua/plugins/git.lua       fugitive + gitsigns
lua/plugins/editor.lua    flash, surround, autopairs, marks
lua/plugins/format.lua    conform + mason-tool-installer (prettier/stylua)
lua/plugins/ui.lua        vim-one (colorscheme), lualine, which-key
```

## Namespace-prefix bindings

Leader is `<Space>`. Single keys act as named "namespace" prefixes, declared through a
readable `namespace('Files', 'f')` helper in `keymaps.lua` that keeps the grouped,
self-documenting structure. which-key labels each group and lists its members when you
hold the prefix.

> Note: the old config's `[Files]`+`<Nop>`+remap pseudo-key trick was dropped — it
> conflicts with which-key (which claims the bare prefix key for its popup). The helper
> now maps the real keys directly, so both the bindings and which-key work.

### `;` — FuzzyFinder (fzf-lua)
| Key | Action |
|---|---|
| `;/` | Fuzzy-search lines in the current file |
| `;f` | Find files |
| `;b` | Buffers |
| `;g` | Live grep across the project |
| `;G` | Live grep across the project, **excluding** test/spec files |

### `f` — Files
| Key | Action |
|---|---|
| `fy` | Copy **relative** path + `:line` to clipboard |
| `fY` | Copy **absolute** path to clipboard |
| `fm` | Rename/move current file via **LSP** (updates imports) |
| `fe` | Toggle file explorer (neo-tree) |
| `ff` | Reveal current file in explorer |

### `s` — Windows
| Key | Action |
|---|---|
| `sv` | Horizontal split (`:split`) |
| `sg` | Vertical split (`:vsplit`) |
| `sc` | Close window · `so` only window |
| `sh/sj/sk/sl` | Move between windows |
| `sb` | Back to previous (alternate) buffer (`:b#`) |
| `ss` | Swap pane positions (`<C-w>R`) |

### `t` — Tabs
| Key | Action |
|---|---|
| `tt` | New tab · `tc` close · `to` only |
| `th/tl` | Previous / next tab |

### `!` — Terminal
| Key | Action |
|---|---|
| `!!` | Run a command in a reusable right-hand tmux pane using one-third of the width (empty command opens/focuses zsh) |
| `!s` / `!v` | Terminal in horizontal / vertical split |
| `<Esc><Esc>` | Leave terminal-insert mode |

### `<leader>g` — Git (fugitive + gitsigns)
> Bare `g` stays native so `gg`, `gd`, `gc`, etc. keep working — Git lives under `<leader>g`.

| Key | Action |
|---|---|
| `<leader>gs` | Status (`:Git`) |
| `<leader>gb` | Blame · `<leader>gl` log · `<leader>gd` diff split |
| `<leader>gp` | Preview hunk · `<leader>gS` stage hunk · `<leader>gR` reset hunk |
| `<leader>gD` (visual) | Mark selected lines for Linediff comparison |
| `<leader>gR` (visual) | Reset an active Linediff comparison |
| `]h` / `[h` | Next / previous hunk |

### Editing / motion / misc
| Key | Action |
|---|---|
| `<leader>saw` | Substitute word under cursor across the file |
| `S` (visual) | Substitute the **selection** across the file — visual twin of `<leader>saw` |
| `<leader>f` | **Format** — whole buffer, or just the selection in visual mode |
| `ae` | Text object: **the entire file** (`vae`, `yae`, `=ae`, …) |
| `<leader>w` | Toggle color-highlight on word under cursor (quickhl-style) |
| `mm` / `mn` / `mp` / `dm` | Toggle bookmark / next / prev / clear (marks.nvim) |
| `/` | Flash jump, 2 chars, across windows (old `easymotion-overwin-f2`) |
| `<leader>/` | Native `/` search (regex, history, `n`/`N`) |
| `<leader><leader>` | Flash jump (free-length) |
| `<leader>S` | Flash treesitter select |
| `gs` / `gS` (visual) | Surround selection — moved off `S`, which is now substitute |
| `gc` / `gcc` | Comment (native, built-in) |
| `<Esc>` | Clear search highlight |

### Linediff
Select one block and press `<leader>gD`, then select the second block and press
`<leader>gD` again. Linediff opens the two selections in a new tab with diff mode
enabled. Edit either temporary buffer and save it to update the corresponding
original block. Use `<leader>gR` in visual mode, or `:LinediffReset`, to close the
comparison and remove its markers.

### Formatting
`<leader>f` runs [conform.nvim](https://github.com/stevearc/conform.nvim): prettier for JS/TS/CSS/HTML/JSON/YAML/Markdown, stylua for Lua, and the language server as a fallback for anything else. Prettier is resolved from the project's own `node_modules/.bin` first (so each repo uses its pinned version and `.prettierrc`), falling back to the mason-installed `prettierd`. `:ConformInfo` shows what will run for the current buffer.

In visual mode only the selection is sent to the formatter. Note this is bounded by what the formatter itself supports: prettier expands the range out to whole statements, while stylua only reformats nodes lying fully inside the range, so a partial-line selection can come back unchanged.

### LSP (buffer-local, active when a server is attached)
| Key | Action |
|---|---|
| `gd` | Definition · `gy` type def · `gi` implementation · `gr` references |
| `K` | Hover docs |
| `<leader>r` | Rename symbol · `<leader>A` code action |
| `<leader>e` | Line diagnostics float · `<leader>F` format |
| `]d` / `[d` | Next / previous diagnostic |

### Completion (blink.cmp, `super-tab` preset)
`<Tab>`/`<S-Tab>` select & accept and jump between snippet placeholders; `<C-Space>`
opens the menu; `<C-e>` dismisses. Sources: LSP, snippets, path, buffer.

## Notes
- Test-runner workflow (old vimux `!t` / `!!`) is left as a minimal terminal placeholder
  under the `!` namespace — wire up your tmux flow there later.
- The `<leader>w` word highlighter uses window-local `matchadd`, so highlights are
  per-window (fine for a starter).
