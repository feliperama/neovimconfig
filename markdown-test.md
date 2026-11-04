# Markdown in Ghostty

Readable **bold**, *italic*, `inline code`, and [Neovim links](https://neovim.io).

## Lists

- Headings and bullets should be styled.
- Nested items stay readable:
  - Images travel through tmux to Ghostty.
- [x] Markdown configuration installed
- [ ] Visually confirm the diagram below

1. Move into the Mermaid block to inspect its source.
2. Press Space m d to view the diagram in its own tab; q returns.

## Code

```lua
local greeting = 'Hello, Ghostty!'
print(greeting)
```

## Mermaid

```mermaid
flowchart LR
    A[Markdown] --> B[Mermaid CLI]
    B --> C[image.nvim]
    C --> D[tmux passthrough]
    D --> E[Ghostty]
```

> Diagrams render inline automatically. Insert mode clears the diagram for editing.

| Shortcut | Action |
| --- | --- |
| Space m r | Toggle Markdown styling |
| Space m d | Open diagram under cursor |
| o (diagram tab) | Open vector SVG externally |
| Space m o | Open SVG directly from Mermaid source |
| Space m R | Refresh the Mermaid PNG/SVG cache |

## Wrapped table separators

Resize the window: thin rules should separate body rows, including wrapped cells,
with heavier top/bottom borders. Insert mode and Space m r should hide the rules.

| Requirement | Evidence / reason |
| --- | --- |
| Keep long requirements readable when the window gets narrow, without changing the source Markdown or losing any text. | Compare the thin rule beneath this entire row with the heavier top and bottom borders. |
| Preserve **bold**, `inline code`, and [links](https://neovim.io/doc/user/). | The rule should meet each column boundary even when link targets are concealed. |
| A short final requirement. | No extra separator below the final row, only the bottom border. |
