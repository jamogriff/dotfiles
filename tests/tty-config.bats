#!/usr/bin/env bats
# Exercises the REAL setup/tty/config script end to end -- no network calls or
# package installs, just symlinks, so safe to run for real against a
# throwaway $HOME. Mirrors desktop-config.bats, minus the pieces the tty
# profile doesn't get (kitty, fonts) and plus the one thing it has that
# desktop doesn't (scripts/mac_display).

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "symlinks gitconfig, tmux, nvim, scripts/t and mac_display into HOME" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  [ -L "$HOME/.gitconfig" ]
  [ "$HOME/.gitconfig" -ef "$REPO_DIR/.gitconfig" ]

  [ -L "$HOME/.tmux.conf" ]
  [ "$HOME/.tmux.conf" -ef "$REPO_DIR/tmux/tmux.conf" ]

  [ -L "$HOME/.config/nvim" ]
  [ "$HOME/.config/nvim" -ef "$REPO_DIR/nvim" ]

  [ -L "$HOME/.local/bin/t" ]
  [ "$HOME/.local/bin/t" -ef "$REPO_DIR/scripts/t" ]

  [ -L "$HOME/.local/bin/mac_display" ]
  [ "$HOME/.local/bin/mac_display" -ef "$REPO_DIR/scripts/mac_display" ]
}

@test "does not symlink kitty or unpack fonts -- desktop-only concerns" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/kitty" ]
  [ ! -d "$HOME/.fonts" ]
}

@test "records the 'tty' profile" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles-profile")" = "tty" ]
}

@test "symlinks every zsh/*.zsh into ZSH_CUSTOM when oh-my-zsh is installed" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  for f in "$REPO_DIR"/zsh/*.zsh; do
    target="$HOME/.oh-my-zsh/custom/$(basename "$f")"
    [ -L "$target" ]
    [ "$target" -ef "$f" ]
  done
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]
  [ ! -d "$HOME/.oh-my-zsh" ]
}
