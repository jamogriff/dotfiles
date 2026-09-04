#!/usr/bin/env bats
# Exercises the REAL init/desktop/install-config script end to end. Unlike
# install-packages/install-nvim it makes no network calls and installs no
# packages -- just symlinks, a font unzip, and one gsettings call -- so it's
# safe to run for real against a throwaway $HOME instead of faking it out.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "symlinks kitty, tmux, nvim and scripts/t into HOME" {
  run bash "$REPO_DIR/init/desktop/install-config"
  [ "$status" -eq 0 ]

  # `-L` tests "is this path a symlink"; `readlink` prints what it points at.
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
  run bash "$REPO_DIR/init/desktop/install-config"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles-profile")" = "desktop" ]
}

@test "warns when .secrets is missing" {
  run bash "$REPO_DIR/init/desktop/install-config"
  [[ "$output" == *"WARNING: Add .secrets file"* ]]
}

@test "symlinks .secrets when present" {
  touch "$REPO_DIR/.secrets"
  run bash "$REPO_DIR/init/desktop/install-config"
  rm -f "$REPO_DIR/.secrets"   # clean up so we don't leave repo state dirty

  [ "$status" -eq 0 ]
  [ -L "$HOME/.local/.secrets" ]
}
