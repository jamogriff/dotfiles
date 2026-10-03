# tmux cheatsheet

Keybindings from `config/.tmux.conf`. The prefix is `Ctrl-Space`; `Prefix`
below means press that first. Mouse support is on, so panes and windows
can also be resized and selected by clicking.

## Sessions

| Keys | Does |
|---|---|
| `Prefix F` | Open the `t` session picker in a new window |
| `Prefix D` | Jump to (or create) the `~/.dotfiles` session |
| `Prefix ^` | Switch to the previous session |
| `Prefix Ctrl-Space` | Send the prefix through to a nested tmux |
| `Prefix r` | Reload the config |

`t` is `scripts/t`, on `$PATH` as `~/.local/bin/t`. With no argument it lists
directories up to three deep under `$HOME` in fzf (dot directories and
`~/Library` are skipped) and switches to a session named after the pick,
creating it if needed. `t <dir>` skips the picker.

## Windows

Numbering starts at 1 and renumbers when a window closes.

| Keys | Does |
|---|---|
| `Prefix c` | New window in the current pane's directory |
| `Prefix n` / `Prefix p` | Next / previous window (repeatable) |
| `Prefix Ctrl-n` / `Prefix Ctrl-p` | Same, for when Ctrl is still held |
| `Prefix Ctrl-l` / `Prefix Ctrl-h` | Same, repeatable |
| `Prefix N` / `Prefix P` | Move this window right / left |
| `Prefix Space` | Toggle between the last two windows |

## Panes

| Keys | Does |
|---|---|
| `Prefix \|` | Split side by side, in the current directory |
| `Prefix -` | Split top and bottom, in the current directory |
| `Ctrl-h/j/k/l` | Move between panes, no prefix. Inside Neovim the same keys move between splits first (vim-tmux-navigator) |
| `Prefix h/j/k/l` | Move between panes (repeatable) |

## Copy mode

`Prefix [` enters copy mode, with vi keys.

| Keys | Does |
|---|---|
| `Space` | Begin selection |
| `Enter` | Yank the selection into the tmux buffer and leave copy mode |
| `Prefix y` | Copy the tmux buffer to the system clipboard (`pbcopy` on macOS, `xclip` on Linux) |

The config also tries to bind `v` to begin selection, but that line is
guarded on `$TMUX_VERSION`, which tmux doesn't set, so it never takes effect.
