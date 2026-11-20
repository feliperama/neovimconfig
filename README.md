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
lua/config/environment.lua shared VS Code / standalone environment detection
lua/config/keymaps.lua    shared key bindings (namespace prefixes + LSP + motion + git …)
lua/config/util.lua       helpers (copy path, quickhl, LSP rename-file, substitute)
lua/config/diagram.lua    Mermaid renderer + preview-local key bindings
lua/config/image.lua      ImageMagick resize override
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

Lazy-loading Markdown shortcuts stay in their plugin specs; completion keys come
from blink.cmp's preset. Preview-only bindings stay with their local preview state.

## VS Code Neovim

The same configuration supports incremental adaptation for VSCode Neovim.
`lua/config/environment.lua` reads `vim.g.vscode`, which the extension sets before
loading `init.lua`, and exposes `is_vscode` and `is_standalone`.

Markdown rendering (`render-markdown.nvim`, `image.nvim`, and `diagram.nvim`) uses
`cond = environment.is_standalone` in its plugin specs. In VS Code these plugins
and their `<Space>md`, `<Space>mo`, `<Space>mR`, and `<Space>mr` bindings are inactive.
Lazy's `cond` retains installed plugins for standalone Neovim, including when
running `:Lazy clean` from VS Code. The Markdown shortcuts below apply only to
standalone Neovim.

For further migration, keep one shared configuration and adapt at ownership boundaries:

- **Environment detection:** reuse `config.environment` instead of spreading
  `vim.g.vscode` checks throughout the configuration.
- **Plugins:** gate terminal/editor-UI plugins with `cond` in their specs; keep
  plugin-specific bindings there so they follow the same gate.
- **Options and shared mappings:** keep these in `config.options` and
  `config.keymaps`; gate host-specific sections with the same environment module.
- **Operations with two implementations:** as they are migrated, put VS Code
  command calls behind a small adapter (for example `config.actions`), letting
  shared mappings call the same action in either host. Add this when needed.

This first step gates only the Markdown rendering stack. Other plugin and mapping
adaptations can follow independently.

## OpenCode file references in tmux

On this Mac, `~/.tmux.conf` binds **Option-click** on a path in the OpenCode
pane. It opens the file as a buffer in the existing Neovim pane to its right,
then focuses that pane. Relative paths use the OpenCode pane's working directory;
`path:line[:column]` and local `file://` links are supported. Normal clicks and
web links are unchanged. If a path wraps across screen lines or has spaces,
use a single-line `file://` link with spaces encoded as `%20`.

Without a mouse, use `Ctrl-b` then `/` to search tmux history. Put the copy-mode
cursor on the path and press `O` (Shift-o) to open it in Neovim.

New Neovim instances register automatically. For a Neovim already open when
installing this integration, run `:lua require('config.tmux_open').register()`
once in the right pane; no restart is needed.

## Markdown in Ghostty + tmux

`render-markdown.nvim` styles headings, lists, tables, and code, with soft wrapping
and hidden column guides while reading. Insert mode reveals the raw Markdown.
Tables use heavy top/bottom borders and thin column and body-row separators.
These rules are display-only: the Markdown source is unchanged. The custom handler
in `lua/config/markdown_tables.lua` reuses render-markdown's internal table parser;
recheck wrapped tables after plugin updates.
`diagram.nvim` renders Mermaid fences inline through `image.nvim`, using the Kitty
graphics backend supported by Ghostty and the `magick_cli` processor.
`lua/config/image.lua` replaces the processor's basic box-sampling resize with
Lanczos filtering to preserve diagram lettering when fitting terminal cells.
Mermaid exports at 2× resolution; terminal-cell fitting can still reduce the
displayed image, so the original in a system viewer may look sharper or larger.

On macOS, install ImageMagick and Neovim's isolated Mermaid CLI:

```sh
brew install imagemagick node
npm install --prefix ~/.local/share/nvim/mermaid-cli --no-audit --no-fund @mermaid-js/mermaid-cli@11.12.0
```

The CLI is pinned to 11.12.0 because it registers the ELK layout engine; the tested
Homebrew CLI 12.0.0 silently fell back to the default layout. The isolated install
does not replace the system `mmdc`. Puppeteer needs its matching browser runtime;
if npm blocks its installation script and no compatible browser is cached, run
`node ~/.local/share/nvim/mermaid-cli/node_modules/puppeteer/install.mjs`.
For a custom `XDG_DATA_HOME`, use Neovim's `stdpath('data')` instead of
`~/.local/share/nvim` in these commands.

`lua/config/diagram.lua` supplies an option-aware Mermaid renderer and preview.
ELK is the default layout; source directions such as `TD` and `LR` are preserved.
A diagram can override the layout with Mermaid YAML frontmatter, for example
`config: { layout: dagre }`. Inline and tab previews remain PNG; external previews
are SVG with a dark background so labels remain readable in system viewers.

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

| Markdown shortcut | Action |
|---|---|
| `<Space>md` | Open diagram under cursor in a tab; `q` / Escape closes it |
| `o` in a Mermaid preview tab | Generate and open SVG in the system's associated application |
| `<Space>mo` | Open Mermaid SVG directly from its source block |
| `<Space>mR` | Invalidate that Mermaid diagram's current PNG/SVG cache and re-render |
| `<Space>mr` | Toggle Markdown styling |

The cache lives in `~/.cache/nvim/diagram-cache/mermaid-local/` (under
`stdpath('cache')` with XDG overrides). Keys include source, rendering options,
format via extension, and the pinned CLI version, so option changes do not reuse
stale output. Refresh regenerates the current layout; it does not randomize it.
Mermaid source remains untouched when previewing, exporting, or refreshing.

## Namespace-prefix bindings

Leader is `<Space>`. Single keys act as named "namespace" prefixes, declared through a
readable `namespace('Files', 'f')` helper in `keymaps.lua` that keeps the grouped,
self-documenting structure. which-key labels each group and lists its members when you
hold the prefix.

Bindings below are Normal mode unless marked otherwise. `<leader>` means `<Space>`.
Plugin defaults and native shortcuts are explicitly identified where listed.

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
| `fde` | Delete current file from disk and close its buffer (discards unsaved edits) |
| `fe` | Toggle file explorer (neo-tree) |
| `ff` | Reveal current file in explorer |

The file explorer shows hidden and Git-ignored files by default.

### `s` — Windows
| Key | Action |
|---|---|
| `sv` | Horizontal split (`:split`) |
| `sg` | Vertical split (`:vsplit`) |
| `sc` | Close window · `so` only window |
| `sh/sj/sk/sl` | Move between windows |
| `sb` | Back to previous (alternate) buffer (`:b#`) |
| `ss` | Swap pane positions (`<C-w>R`) |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move left / down / up / right between Neovim splits and tmux panes (smart-splits; tmux needs matching bindings) |
| `<Up>` / `<Down>` | Decrease / increase window height by 2 rows |
| `<Left>` / `<Right>` | Increase / decrease window width by 2 columns |
| `<C-w>=` | Equalize split widths and heights in the current tab (native; press Ctrl-w, then `=`) |

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
| `q` | Quit current window (overrides native macro recording) |
| `<leader>q` | Start recording a macro; then choose a register (native `q` stops recording) |
| `<leader>saw` | Substitute word under cursor across the file |
| `S` (visual) | Substitute the **selection** across the file — visual twin of `<leader>saw` |
| `<leader>f` | **Format** — whole buffer, or just the selection in visual mode |
| `ae` (visual / operator-pending) | Text object: **the entire file** (`vae`, `yae`, `=ae`, …) |
| `<leader>w` | Toggle color-highlight on word under cursor (quickhl-style) |
| `mm` / `mn` / `mp` / `dm` | Toggle bookmark / next / prev / clear (marks.nvim) |
| `/` (Normal mode only) | Flash jump, 2 chars, across windows; visual/operator-pending `/` stays native |
| `<leader>/` | Native `/` search (regex, history, `n`/`N`) |
| `<leader><leader>` (normal / visual / operator-pending) | Flash jump (free-length) |
| `<leader>S` (normal / visual / operator-pending) | Flash treesitter select |
| `gs` / `gS` (visual) | Surround selection / surround on new lines (nvim-surround); `S` substitutes instead |
| `gc` / `gcc` | Comment (native, built-in) |
| `<Esc>` | Clear search highlight |

### Folding and list navigation
| Key | Action |
|---|---|
| `<leader>0` | Open all folds (sets fold level to 99) |
| `<leader>1` … `<leader>9` | Set fold level to 0 … 8: `1` closes all folds, higher numbers leave more outer levels open |
| `<Enter>` | Open a closed fold or close the innermost fold under the cursor; otherwise native Enter |
| `<Enter>` in quickfix / location list | Jump to the entry and close that list |

Other special buffers retain native Enter. Folds use Treesitter and start open.

### Surround plugin defaults (nvim-surround)
These stay enabled alongside the custom visual `gs` / `gS` mappings above.

| Key | Action |
|---|---|
| `ys{motion}{pair}` / `yss{pair}` | Surround a motion / current line, e.g. `ysiw)` |
| `yS{motion}{pair}` / `ySS{pair}` | Surround a motion / current line with the pair on new lines |
| `ds{pair}` | Delete surrounding pair |
| `cs{old}{new}` / `cS{old}{new}` | Change pair / change pair onto new lines |
| `<C-g>s` / `<C-g>S` (insert) | Insert a surrounding pair / insert it on new lines |

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
| `<leader>e` | Line diagnostics float · `<leader>F` format buffer via LSP (not conform) |
| `]d` / `[d` | Next / previous diagnostic |

### Completion (blink.cmp, `super-tab` preset)
These are insert-mode plugin defaults, not Normal-mode window bindings.
Sources: LSP, snippets, path, buffer.

| Key | Action |
|---|---|
| `<Tab>` | Accept completion (selecting the first item if needed); otherwise jump to next snippet placeholder, then native Tab |
| `<S-Tab>` | Jump to previous snippet placeholder; otherwise native Shift-Tab (does not select the previous completion) |
| `<Up>` / `<Down>` or `<C-p>` / `<C-n>` | Select previous / next completion |
| `<C-Space>` | Show completion menu, then show / hide documentation |
| `<C-e>` | Cancel completion; otherwise native behavior |
| `<C-b>` / `<C-f>` | Scroll completion documentation up / down |
| `<C-k>` | Show / hide signature help; otherwise native behavior |

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

The search window title reminds you that **Ctrl-g alternates search modes**.
The header names the mode you will switch **to**. With `;g` / `;G`, the first
press switches from fuzzy matching to live regex; the next press fuzzy-filters
those regex results. Start with `;r` for regex-then-fuzzy refinement with one press.

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
- `!!` runs a command in a reusable tmux pane; there is no dedicated `!t` test-runner mapping.
- The `<leader>w` word highlighter uses window-local `matchadd`, so highlights are
  per-window (fine for a starter).
