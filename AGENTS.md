# Working on this configuration

- Read `README.md` and nearby comments before changing behavior; preserve existing keybindings unless asked otherwise.
- Keep options in `lua/config/options.lua`, shared mappings in `lua/config/keymaps.lua`, and plugin specs in `lua/plugins/`. Keep mappings local when lazy loading or preview state requires it.
- Give mappings descriptions, use the existing namespace groups, and update README shortcut tables when bindings change.
- Prefer native Neovim capabilities and existing plugins over new dependencies. Match surrounding Lua style; avoid unrelated reformatting.
- Preserve Ghostty/tmux integration and documented Mermaid/image workarounds unless the task specifically changes them.
- Check Lua syntax and relevant mappings after changes. For rendering changes, use `markdown-test.md` in Ghostty/tmux; headless checks do not validate graphics. Report checks you could not perform.
