#!/usr/bin/env bash
#
# Sourced by setup/desktop/config and setup/tty/config; not runnable on its own
# (hence the .bash extension and no exec bit — nothing under setup/ but this
# directory is a library). Expects the caller to have set $DOTFILES to the repo
# root.
#
# These three helpers replace the rm + ln -s pairs both config scripts used to
# hand-write once per target, near-identically in both files. What's left in
# each script is the part that genuinely differs between profiles: which names
# it syncs.

# Symlink one entry in config/ into place. The convention config/ is named for
# makes this a two-line rule with no per-target manifest:
#
#   directory -> ~/.config/<name>     config/nvim       -> ~/.config/nvim
#   file      -> ~/<name>             config/.tmux.conf -> ~/.tmux.conf
#
# The file case is a plain identity mapping with zero exceptions, which is why
# every flat entry in config/ keeps its leading dot (or gains one, as
# config/.tmux.conf did when it moved out of tmux/): each is named exactly what
# it becomes in $HOME, so this function never has to special-case a name.
#
# It deliberately does NOT decide *which* names a profile gets — kitty and
# .ideavimrc are desktop-only, and nothing guarantees a tty-only entry won't
# show up later. That stays an explicit list in each config script; this only
# handles how to link one name once a profile has picked it.
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
  # than our symlink — a hand-rolled ~/.config/nvim predating this repo, or the
  # leftovers of a source path that moved — and rm -f refuses to remove one.
  rm -rf "$dest"
  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
}

# The one entry in config/ the rule above can't express. oh-my-zsh sources every
# *.zsh file in $ZSH_CUSTOM, in alphabetical order and after everything else it
# loads, so it's the supported place for personal config that must survive the
# installer rewriting ~/.zshrc — but it wants the individual files, not a
# directory symlink, so config/zsh is linked file by file instead of as a unit.
# Symlinking rather than copying still keeps them under version control here.
#
# Guarded on ~/.oh-my-zsh actually existing: `dotfiles bootstrap` always runs
# setup/zsh first so it will, but `dotfiles sync config` can run at any time.
# Note we must not create ~/.oh-my-zsh ourselves to satisfy that check —
# setup/zsh treats the presence of that directory as "oh-my-zsh is installed"
# and would skip it.
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

# scripts/ isn't part of config/ — it follows the ~/.local/bin/<name> convention
# rather than anything under ~/.config — but both profiles symlink from it, so
# the mechanics live here alongside the rest.
link_bin() {
  local name="$1"
  mkdir -p "$HOME/.local/bin"
  rm -f "$HOME/.local/bin/$name"
  ln -s "$DOTFILES/scripts/$name" "$HOME/.local/bin/$name"
  echo "Linked $HOME/.local/bin/$name -> $DOTFILES/scripts/$name"
}
