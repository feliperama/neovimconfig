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
lua/plugins/markdown.lua  Markdown styling, inline images + Mermaid diagrams
```

## Markdown in Ghostty + tmux

`render-markdown.nvim` styles headings, lists, tables, and code, with soft wrapping
and hidden column guides while reading. Insert mode reveals the raw Markdown.
`diagram.nvim` renders Mermaid fences inline through `image.nvim`, using the Kitty
graphics backend supported by Ghostty and the `magick_cli` processor.
`lua/config/image.lua` replaces the processor's basic box-sampling resize with
Lanczos filtering to preserve diagram lettering when fitting terminal cells.
Mermaid exports at 2× resolution; terminal-cell fitting can still reduce the
displayed image, so the original in a system viewer may look sharper or larger.

On macOS, install the two external tools (Mermaid CLI includes its browser runtime):

```sh
brew install imagemagick mermaid-cli
```

For tmux 3.3+, put these in `~/.tmux.conf` and reload it:

```tmux
set -gq allow-passthrough on
set -g visual-activity off
set -g focus-events on
```

Open `nvim ~/.config/nvim/markdown-test.md` in Ghostty, including inside tmux.
Diagrams render automatically, clear during Insert mode, and refresh on leaving it.
Images also clear when Neovim loses focus and return when it regains focus.
Exit Neovim normally before killing or respawning its tmux pane: a forced kill
can bypass Kitty graphics cleanup and leave stale images in the terminal.
Use `<Space>mr` to toggle Markdown styling and `<Space>md` inside a Mermaid block
to view the diagram in a dedicated tab (`q` returns). Ordinary Markdown image
links also render inline. `:ImageReport` and `:checkhealth render-markdown` provide
diagnostics. The existing `markdown` and `markdown_inline` Treesitter parsers are
sufficient; a separate Mermaid parser is not required.

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
| `;g` | Fuzzy-search project lines (lightweight filters) |
| `;G` | Same fuzzy search, **excluding** test/spec files |
| `;r` | Live regex search, including data and large files |

See [Search tips and performance](#search-tips-and-performance) for matching syntax,
search exclusions, and large-workspace workflows.

### `f` — Files
| Key | Action |
|---|---|
| `fy` | Copy **relative** path + `:line` to clipboard |
| `fY` | Copy **absolute** path + `:line` to clipboard |
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

## Search tips and performance

### Fuzzy matching versus live grep

`;g` and `;G` load project lines into fzf, which allows gaps between query characters.
For example, `strip.createtoken` matches `t.stripe.createToken`. Lowercase queries
match mixed-case text by default. Close matches rank first, but scattered letters
across a long line can also match.

To tighten a search, prefix individual fragments with `'` (no closing quote):

| Query | Meaning |
|---|---|
| `strip.createtokn` | Fully fuzzy; gaps are allowed anywhere |
| `'strip createtokn` | Literal `strip`, with fuzzy matching for `createtokn` |
| `'strip 'createtok` | Both literal fragments must appear on the same line |

fzf has no built-in maximum-gap setting. Mixing exact and fuzzy fragments is a useful
way to reduce unrelated results while tolerating missing characters where needed.

`;r` uses ripgrep's **regex matching**, rather than fuzzy matching. It searches files
as you type and feeds only matching lines to the picker.

### Default search exclusions

To keep the fuzzy candidate set manageable, `;g` and `;G` skip:

- CSV files (`*.csv`).
- Dependency lockfiles: `package-lock.json`, `npm-shrinkwrap.json`, `yarn.lock`,
  `pnpm-lock.yaml`, `bun.lock`, and `bun.lockb`.
- Files larger than **1 MiB**, including source files over that limit.
- `.git` metadata.

`;G` also skips test/spec files and test directories. Use **`;r`** when you need
CSVs, lockfiles, or large files: it has none of those data/size exclusions.
All three mappings include hidden files, exclude `.git` metadata, respect ignore
files such as `.gitignore` and `.rgignore`, and limit displayed line length to 4,096
columns. Their options live in `lua/config/keymaps.lua`.

### Faster searches in large workspaces

**1. Search a smaller directory.** Searches normally start at Neovim's current
working directory (`:pwd`). If it contains several repositories, the candidate set
includes all of them, including nested copies of shared packages. Scope a picker
without changing Neovim's working directory:

```vim
:FzfLua grep_project cwd=~/acuity/takecasper/account
```

This direct command uses the plugin defaults, not the lightweight filters attached
to `;g` / `;G`. To use those mappings within a smaller scope, set the window-local
working directory first, then press `;g`:

```vim
:lcd ~/acuity/takecasper/account
```

Use `:lcd -` to return to the previous directory.

**2. Grep first, then fuzzy-filter.** This is especially useful when searching across
multiple repositories:

1. Press `;r`.
2. Enter a reliable fragment, such as `stripe`, to narrow the results with ripgrep.
3. Press **Ctrl-g** to switch to fuzzy filtering of those results.
4. Refine the fuzzy query, for example with `createtokn`.

Only lines matching the initial regex are available for fuzzy refinement. Press
Ctrl-g again to return to regex search if you need to broaden the initial search.

**3. Use project-specific `.rgignore` rules for bulk data.** Place a `.rgignore` in
the workspace root to exclude exports or generated files from ripgrep searches:

```gitignore
# Example rules — choose the paths and file types appropriate for the project.
*.csv
package-lock.json
**/scripts/removeTechIssueToAllSchoolExportFormat/full_queries/
```

These rules affect both the Neovim searches (including `;r`) and terminal ripgrep
searches under that workspace. They do not change Git tracking. Avoid excluding an
entire shared-code directory just because it is heavy: nested copies may differ.

### Why reducing the candidate set helps

Fuzzy project search loads every eligible line, not just lines containing a keyword.
Large CSVs, JSON exports, lockfiles, and repeated package copies therefore affect
startup time and filtering work even when they are unrelated to the query.

In a local `takecasper` measurement, the lightweight filters reduced the candidate
set from about **1.86 million to 717,000 lines**. A command-line ripgrep → fzf search
for `strip.createtoken` took **0.925 s before** and **0.321 s after**, while retaining
the expected source-code match. These are illustrative local measurements, not
Neovim UI timings; results vary with workspace contents and machine load.

Further reading:

- [ripgrep: automatic filtering and ignore files](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#automatic-filtering)
- [fzf: performance considerations](https://github.com/junegunn/fzf#performance)
- [fzf-lua: search commands](https://github.com/ibhagwan/fzf-lua#search)

## Notes
- Test-runner workflow (old vimux `!t` / `!!`) is left as a minimal terminal placeholder
  under the `!` namespace — wire up your tmux flow there later.
- The `<leader>w` word highlighter uses window-local `matchadd`, so highlights are
  per-window (fine for a starter).
