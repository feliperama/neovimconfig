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
