#!/usr/bin/env bash
#
# Sourced by setup/desktop/config and setup/tty/config; not runnable on its own.
# Expects the caller to have set $DOTFILES to the repo root.

# Symlink one entry in config/ into place, deriving the destination from its
# shape rather than a per-target manifest:
#
#   directory -> ~/.config/<name>     config/nvim       -> ~/.config/nvim
#   file      -> ~/<name>             config/.tmux.conf -> ~/.tmux.conf
#
# *Which* names a profile gets stays an explicit list in each config script.
link_config() {
  local name="$1"
  local src="$DOTFILES/config/$name"
  local dest

  if [ ! -e "$src" ]; then
    echo "WARNING: no config/$name in this repo; skipping." >&2
    return 0
  fi

  if [ -d "$src" ]; then
    dest="$HOME/.config/$name"
  else
    dest="$HOME/$name"
  fi

  mkdir -p "$(dirname "$dest")"

  # rm -rf rather than rm -f: what's at $dest may be a real directory rather
  # than our symlink — a hand-rolled ~/.config/nvim predating this repo, say.
  rm -rf "$dest"
  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
}

# oh-my-zsh sources every *.zsh in $ZSH_CUSTOM, but wants the individual files,
# not a directory symlink — so config/zsh can't use the rule above.
#
# Guarded on ~/.oh-my-zsh existing, since `sync config` can run before setup/zsh
# has. We must not create that directory ourselves to satisfy the check: setup/zsh
# reads its presence as "oh-my-zsh is installed" and would skip itself.
link_zsh_custom() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo 'WARNING: ~/.oh-my-zsh not found; skipping zsh custom symlinks. Run `dotfiles bootstrap` first, then re-run this.'
    return 0
  fi

  mkdir -p "$zsh_custom"
  local f
  for f in "$DOTFILES"/config/zsh/*.zsh; do
    rm -f "$zsh_custom/$(basename "$f")"
    ln -s "$f" "$zsh_custom/$(basename "$f")"
  done
  echo "Linked $zsh_custom/*.zsh -> $DOTFILES/config/zsh/"
}

# scripts/ isn't part of config/ — it follows ~/.local/bin/<name> — but both
# profiles link from it, so the mechanics live here with the rest.
link_bin() {
  local name="$1"
  mkdir -p "$HOME/.local/bin"
  rm -f "$HOME/.local/bin/$name"
  ln -s "$DOTFILES/scripts/$name" "$HOME/.local/bin/$name"
  echo "Linked $HOME/.local/bin/$name -> $DOTFILES/scripts/$name"
}
