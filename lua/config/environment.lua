-- VSCode Neovim sets this before loading init.lua.
local is_vscode = vim.g.vscode == true or vim.g.vscode == 1

return {
  is_vscode = is_vscode,
  is_standalone = not is_vscode,
}
