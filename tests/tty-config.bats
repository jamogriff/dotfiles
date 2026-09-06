#!/usr/bin/env bats
# Exercises the real setup/tty/config end to end -- just symlinks, so safe to
# run against a throwaway $HOME. Mirrors desktop-config.bats, minus what tty
# doesn't get and plus scripts/mac_display.

load test_helper

# Every name under config/ this profile symlinks...
SYNCED=".gitconfig .tmux.conf nvim"

# ...and every name it deliberately doesn't: the desktop-only entries, plus
# `zsh`, which both profiles handle via $ZSH_CUSTOM instead.
NOT_SYNCED="kitty .ideavimrc zsh"

setup() {
  fake_home
  use_mocks
}

@test "symlinks every config/ entry this profile syncs to its convention path" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  for name in $SYNCED; do
    assert_linked "$name"
  done
}

@test "every entry in config/ is either synced or deliberately skipped" {
  assert_all_entries_accounted_for "$SYNCED" "$NOT_SYNCED"
}

@test "does not link the desktop-only entries, or unpack fonts" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  assert_not_linked kitty
  assert_not_linked .ideavimrc
  [ ! -d "$HOME/.fonts" ]
}

@test "symlinks scripts/t and scripts/mac_display into ~/.local/bin" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  [ -L "$HOME/.local/bin/t" ]
  [ "$HOME/.local/bin/t" -ef "$REPO_DIR/scripts/t" ]

  [ -L "$HOME/.local/bin/mac_display" ]
  [ "$HOME/.local/bin/mac_display" -ef "$REPO_DIR/scripts/mac_display" ]
}

@test "is idempotent -- a second run leaves the same links, not an error" {
  bash "$REPO_DIR/setup/tty/config"
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  for name in $SYNCED; do
    assert_linked "$name"
  done
}

@test "records the 'tty' profile" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles-profile")" = "tty" ]
}

@test "does not link .env -- machine-specific env vars are a desktop concern" {
  touch "$REPO_DIR/.env"
  run bash "$REPO_DIR/setup/tty/config"
  rm -f "$REPO_DIR/.env"

  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.env" ]
}

@test "symlinks every config/zsh/*.zsh into ZSH_CUSTOM when oh-my-zsh is installed" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]

  for f in "$REPO_DIR"/config/zsh/*.zsh; do
    target="$HOME/.oh-my-zsh/custom/$(basename "$f")"
    [ -L "$target" ]
    [ "$target" -ef "$f" ]
  done

  [ ! -e "$HOME/.config/zsh" ]
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run bash "$REPO_DIR/setup/tty/config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]
  [ ! -d "$HOME/.oh-my-zsh" ]
}
