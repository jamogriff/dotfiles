#!/usr/bin/env bats
# Exercises the REAL setup/desktop/config script end to end. Unlike
# install-packages/install-nvim it makes no network calls and installs no
# packages -- just symlinks, a font unzip, and one gsettings call -- so it's
# safe to run for real against a throwaway $HOME instead of faking it out.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "symlinks gitconfig, kitty, tmux, nvim and scripts/t into HOME" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  # `-L` tests "is this path a symlink"; `readlink` prints what it points at.
  [ -L "$HOME/.gitconfig" ]
  [ "$HOME/.gitconfig" -ef "$REPO_DIR/.gitconfig" ]

  [ -L "$HOME/.config/kitty" ]
  [ "$HOME/.config/kitty" -ef "$REPO_DIR/kitty" ]

  [ -L "$HOME/.tmux.conf" ]
  [ "$HOME/.tmux.conf" -ef "$REPO_DIR/tmux/tmux.conf" ]

  [ -L "$HOME/.config/nvim" ]
  [ "$HOME/.config/nvim" -ef "$REPO_DIR/nvim" ]

  [ -L "$HOME/.local/bin/t" ]
  [ "$HOME/.local/bin/t" -ef "$REPO_DIR/scripts/t" ]
}

@test "records the 'desktop' profile" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles-profile")" = "desktop" ]
}

@test "warns when .secrets is missing" {
  run bash "$REPO_DIR/setup/desktop/config"
  [[ "$output" == *"WARNING: Add .secrets file"* ]]
}

@test "symlinks .secrets when present" {
  touch "$REPO_DIR/.secrets"
  run bash "$REPO_DIR/setup/desktop/config"
  rm -f "$REPO_DIR/.secrets"   # clean up so we don't leave repo state dirty

  [ "$status" -eq 0 ]
  [ -L "$HOME/.local/.secrets" ]
}

@test "symlinks every zsh/*.zsh into ZSH_CUSTOM when oh-my-zsh is installed" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  # Every file in the repo's zsh/ dir should land in custom/ as a symlink back
  # to it, so editing the repo copy takes effect without re-running this script.
  for f in "$REPO_DIR"/zsh/*.zsh; do
    target="$HOME/.oh-my-zsh/custom/$(basename "$f")"
    [ -L "$target" ]
    [ "$target" -ef "$f" ]
  done
}

@test "replaces a stale zsh custom symlink instead of erroring" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  ln -s /nonexistent/aliases.zsh "$HOME/.oh-my-zsh/custom/aliases.zsh"

  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ "$HOME/.oh-my-zsh/custom/aliases.zsh" -ef "$REPO_DIR/zsh/aliases.zsh" ]
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]

  # Creating the dir here would make install-zsh think oh-my-zsh is already
  # installed and skip it entirely -- the exact trap this guard exists to avoid.
  [ ! -d "$HOME/.oh-my-zsh" ]
}
