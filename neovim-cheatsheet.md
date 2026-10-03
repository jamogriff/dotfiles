# Neovim cheatsheet

Keybindings and plugin-manager usage for `config/nvim`. Leader is `Space`.
Bindings marked *desktop* come from plugins the `tty` profile doesn't load.

## Editing

| Keys | Mode | Does |
|---|---|---|
| `jk` / `kj` | insert | Escape |
| `j` / `k` | normal | Move by screen line when wrapped (a count moves by real lines) |
| `>` / `<` | visual | Indent and keep the selection |
| `y` | visual | Yank without moving the cursor |
| `p` | visual | Paste over the selection without overwriting the register |
| `;;` / `,,` | insert | Append `;` or `,` at end of line |
| `Alt-j` / `Alt-k` | normal, insert | Move the current line down / up |
| `Ctrl-Up/Down/Left/Right` | normal | Resize the window by 2 |
| `q:` | normal | Remapped to `:q` (no command-line window) |
| `Leader k` | normal | Clear search highlight |
| `Leader o` | normal | Open the file in the OS default app |
| `Leader q` | normal | Close the buffer, keep the window (bufdelete) |
| `Leader 1` | normal, terminal | Toggle the floating scratch terminal (floaterm) |
| `*` | visual | Search for the selection (visual-star-search) |
| `gcc` / `gc{motion}` | normal | Comment toggle (vim-commentary) |
| `ys` / `cs` / `ds` | normal | Add / change / delete surroundings (vim-surround) |
| `gS` / `gJ` | normal | Split / join a one-liner (splitjoin) |
| `Ctrl-u` / `Ctrl-d` | normal | Smooth half-page scroll (neoscroll) |
| `Ctrl-h/j/k/l` | normal | Move between splits and tmux panes (vim-tmux-navigator) |

System clipboard is the default register (`clipboard=unnamedplus`).

## Finding things (Telescope)

| Keys | Does |
|---|---|
| `Leader f` | Find files (respects `.gitignore`, shows hidden) |
| `Leader F` | Find all files, ignores nothing |
| `Leader g` | Live grep with ripgrep args (`foo -t php`) |
| `Leader b` | Open buffers |
| `Leader h` | Recent files |
| `Leader s` | Document symbols from the LSP |
| `Leader n` | Toggle the file tree at the current file (nvim-tree) |

Inside a picker: `kj` closes, `Ctrl-Up` / `Ctrl-Down` walk the prompt history.
The start screen (dashboard) offers the same three: `f` files, `h` recent, `g` grep.

## Completion (nvim-cmp)

| Keys | Does |
|---|---|
| `Tab` / `Shift-Tab` | Next / previous item, or open the menu |
| `Ctrl-n` / `Ctrl-p` | Next / previous item |
| `Enter` | Confirm |
| `Ctrl-Space` | Open the menu |
| `Ctrl-e` | Close the menu |
| `Ctrl-d` / `Ctrl-f` | Scroll docs |

Snippets (LuaSnip), expand with completion. PHP: `class`, `pubf`, `prif`,
`prof`, `testt`, `testa`. TypeScript: `import`.

## Text objects

Treesitter: `if`/`af` function, `ic`/`ac` class, `ia`/`aa` argument.
Git hunk (*desktop*): `ih`.

## LSP (*desktop*)

| Keys | Does |
|---|---|
| `K` | Hover docs |
| `gd` / `gD` | Definition / declaration |
| `gi` | Implementation |
| `gr` | References (Telescope) |
| `Leader D` | Type definition |
| `Leader rn` | Rename symbol |
| `Leader d` | Show the diagnostic under the cursor |
| `[d` / `]d` | Previous / next diagnostic |

Diagnostics show as signs only, never inline text. `:Trouble` lists them.
`:Neogen` writes a docblock for the thing under the cursor.

## Git (*desktop*, gitsigns)

| Keys | Does |
|---|---|
| `]c` / `[c` | Next / previous hunk |
| `Leader hs` / `Leader hr` | Stage / reset hunk (normal or visual) |
| `Leader hS` / `Leader hR` | Stage / reset the whole buffer |
| `Leader hp` / `Leader hi` | Preview hunk in a float / inline |
| `Leader hb` | Blame the line |
| `Leader hd` / `Leader hD` | Diff against index / against `HEAD~` |
| `Leader hq` / `Leader hQ` | Hunks to the quickfix list (buffer / all) |
| `Leader tb` / `Leader tw` | Toggle line blame / word diff |

`:G` opens fugitive for anything else.

## lazy.nvim

Plugins are listed in `config/nvim/lua/user/plugins.lua` and pinned in
`lazy-lock.json`. Every plugin defaults to `version = "*"`, the latest stable
tag.

| Command | Does |
|---|---|
| `:Lazy` | The UI |
| `:Lazy sync` | Install, clean and update. Run after editing `plugins.lua` |
| `:Lazy update` | Update everything to the latest matching tag |
| `:Lazy restore` | Reset every plugin to the commit in `lazy-lock.json` |
| `:Lazy check` | Look for updates without installing |
| `:checkhealth lazy` | Sanity-check the install |

To add a plugin, add an entry to `plugins.lua` (desktop-only ones go in the
`if not profile.is_tty()` block) and run `:Lazy sync`.

## mason.nvim (*desktop*)

Language servers come from the `ensure_installed` list on the
`mason-lspconfig.nvim` entry in `plugins.lua`. They install into
`~/.local/share/nvim/mason` and only need some runtime for their language
on `$PATH`: Node, Python or Ruby from `install-version-managers`.

| Command | Does |
|---|---|
| `:Mason` | Browse, install and uninstall by hand |
| `:MasonInstall <name>` / `:MasonUninstall <name>` | One-off, without touching `ensure_installed` |
| `:MasonUpdate` | Refresh the registry index |
| `:MasonLog` | Logs for a server that's failing |

To add a server permanently, add its **lspconfig** name (not the mason
package name, they differ: mason's `html-lsp` is lspconfig's `html`, see
[the registry](https://mason-registry.dev/registry/list)) to
`ensure_installed`, then enable it in `config/nvim/lua/user/plugins/lspconfig.lua`:
either add it to the `vim.lsp.enable({...})` list, or if it needs settings
(like `intelephense`'s licence key), call `vim.lsp.config('name', {...})`
first and `vim.lsp.enable('name')` after.

`ruby_lsp` needs a Ruby on `$PATH` before nvim's first launch; otherwise
`:MasonInstall ruby-lsp` by hand once one exists. `intelephense` reads its
licence from `INTELEPHENSE_LICENSE` in `.env`.
