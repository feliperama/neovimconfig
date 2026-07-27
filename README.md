# nvim-modern

A clean, minimal Neovim **0.12** starter: Lua + native LSP, as an isolated alternative
to a vim-plug + coc.nvim setup. Nothing here touches your existing `~/.config/nvim`.

## Launch (isolated)

```sh
NVIM_APPNAME=nvim-modern nvim
```

`NVIM_APPNAME` makes Neovim use:

| Purpose | Path |
|---|---|
| config | `~/.config/nvim-modern` |
| data (plugins, mason, parsers) | `~/.local/share/nvim-modern` |
| state (undo, shada, logs) | `~/.local/state/nvim-modern` |

So the plugin-manager bootstrap and every server/parser stays fully separate from your
current config. Make an alias once you're happy with it:

```sh
alias nvm='NVIM_APPNAME=nvim-modern nvim'
```

## Prerequisites

- **Neovim ≥ 0.11** (built/tested on 0.12.4).
- `git`, a C compiler (Xcode CLT), `node` — for LSP servers.
- **`tree-sitter` CLI** — required by nvim-treesitter's *main* branch to compile parsers.
  Installed via `brew install tree-sitter-cli`.
- `fzf`, `ripgrep` (`rg`), `fd` — used by the fuzzy finder. All already present.

## First run

On first launch everything bootstraps automatically:

1. **lazy.nvim** self-installs, then installs all plugins.
2. **`:Lazy`** — plugin manager UI (install / update / profile / clean). Runs `:Lazy sync`
   to reconcile with the specs.
3. **`:Mason`** — LSP server installer UI. `lua_ls` and `typescript-language-server` are
   installed automatically (via `mason-lspconfig`'s `ensure_installed`) the first time you
   open a Lua/TS/JS file. Use `:Mason` to add more.
4. Treesitter parsers (`typescript`, `tsx`, `javascript`, `lua`, `json`, …) install on
   startup; `:TSUpdate` updates them.

> This config was pre-synced during setup, so your first interactive launch is already warm.

## File layout

```
init.lua                  entry: leader, options, lazy bootstrap, module requires
lua/config/options.lua    editor settings
lua/config/keymaps.lua    all key bindings (namespace prefixes + LSP + motion + git …)
lua/config/util.lua       helpers (copy path, quickhl, LSP rename-file)
lua/plugins/lsp.lua       mason + lspconfig + blink.cmp + lazydev
lua/plugins/treesitter.lua
lua/plugins/finder.lua    fzf-lua
lua/plugins/explorer.lua  neo-tree
lua/plugins/git.lua       fugitive + gitsigns
lua/plugins/editor.lua    flash, surround, autopairs, marks
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

### `t` — Tabs
| Key | Action |
|---|---|
| `tt` | New tab · `tc` close · `to` only |
| `th/tl` | Previous / next tab |

### `!` — Terminal (placeholder; wire up tmux/vimux later)
| Key | Action |
|---|---|
| `!!` | Open terminal |
| `!s` / `!v` | Terminal in horizontal / vertical split |
| `<Esc><Esc>` | Leave terminal-insert mode |

### `<leader>g` — Git (fugitive + gitsigns)
> Bare `g` stays native so `gg`, `gd`, `gc`, etc. keep working — Git lives under `<leader>g`.

| Key | Action |
|---|---|
| `<leader>gs` | Status (`:Git`) |
| `<leader>gb` | Blame · `<leader>gl` log · `<leader>gd` diff split |
| `<leader>gp` | Preview hunk · `<leader>gS` stage hunk · `<leader>gR` reset hunk |
| `]h` / `[h` | Next / previous hunk |

### Editing / motion / misc
| Key | Action |
|---|---|
| `<leader>saw` | Substitute word under cursor across the file |
| `<leader>w` | Toggle color-highlight on word under cursor (quickhl-style) |
| `mm` / `mn` / `mp` / `dm` | Toggle bookmark / next / prev / clear (marks.nvim) |
| `<leader><leader>` | Flash jump (easymotion replacement) |
| `<leader>S` | Flash treesitter select |
| `gc` / `gcc` | Comment (native, built-in) |
| `<Esc>` | Clear search highlight |

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
