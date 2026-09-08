#!/usr/bin/env bats
# Exercises the real src/link-config for both profiles -- symlinks and nothing
# else, so safe to run against a throwaway $HOME.
#
# Assertions are driven off SYNCED/NOT_SYNCED rather than hand-written per
# target: that's what makes an unwired config/ entry a failure, not a no-op.

load test_helper

DESKTOP_SYNCED=".gitconfig .ideavimrc .tmux.conf kitty nvim"
TTY_SYNCED=".gitconfig nvim"

# `zsh` is on both lists: it goes into $ZSH_CUSTOM file by file instead, covered
# by its own tests further down.
DESKTOP_NOT_SYNCED="zsh"
TTY_NOT_SYNCED="kitty .ideavimrc .tmux.conf zsh"

setup() {
  fake_home
  fake_repo
  use_mocks
}

link_config_for() {
  DOTFILES_PROFILE="$1" bash "$REPO_DIR/src/link-config"
}

@test "desktop symlinks every config/ entry it syncs to its convention path" {
  run link_config_for desktop
  [ "$status" -eq 0 ]

  for name in $DESKTOP_SYNCED; do
    assert_linked "$name"
  done
}

@test "tty symlinks every config/ entry it syncs to its convention path" {
  run link_config_for tty
  [ "$status" -eq 0 ]

  for name in $TTY_SYNCED; do
    assert_linked "$name"
  done
}

@test "every entry in config/ is either synced or deliberately skipped, on both profiles" {
  assert_all_entries_accounted_for "$DESKTOP_SYNCED" "$DESKTOP_NOT_SYNCED"
  assert_all_entries_accounted_for "$TTY_SYNCED" "$TTY_NOT_SYNCED"
}

@test "tty links none of the desktop-only entries" {
  run link_config_for tty
  [ "$status" -eq 0 ]

  assert_not_linked kitty
  assert_not_linked .ideavimrc
  assert_not_linked .tmux.conf
}

@test "desktop links scripts/t, tty links scripts/mac_display, neither links both" {
  run link_config_for desktop
  [ "$status" -eq 0 ]
  [ "$HOME/.local/bin/t" -ef "$REPO_DIR/scripts/t" ]
  [ ! -e "$HOME/.local/bin/mac_display" ]

  fake_home
  run link_config_for tty
  [ "$status" -eq 0 ]
  [ "$HOME/.local/bin/mac_display" -ef "$REPO_DIR/scripts/mac_display" ]
  [ ! -e "$HOME/.local/bin/t" ]
}

@test "replaces a real file or directory sitting at a destination path" {
  # The drift case re-linking exists for. rm -f alone wouldn't clear the
  # directory, so this is worth pinning down.
  mkdir -p "$HOME/.config/nvim/lua"
  touch "$HOME/.config/nvim/init.lua"
  echo 'not a symlink' > "$HOME/.gitconfig"

  run link_config_for desktop
  [ "$status" -eq 0 ]

  assert_linked nvim
  assert_linked .gitconfig
}

@test "is idempotent -- a second run leaves the same links, not an error" {
  link_config_for desktop
  run link_config_for desktop
  [ "$status" -eq 0 ]

  for name in $DESKTOP_SYNCED; do
    assert_linked "$name"
  done
}

@test "exits non-zero without a profile, before linking anything" {
  run env -u DOTFILES_PROFILE bash "$REPO_DIR/src/link-config"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTFILES_PROFILE is unset"* ]]
  [ ! -e "$HOME/.gitconfig" ]
}

@test "warns when .env is missing" {
  run link_config_for desktop
  [[ "$output" == *"WARNING: no .env in the repo root"* ]]
  [ ! -e "$HOME/.env" ]
}

@test "symlinks .env to ~/.env on both profiles" {
  # .env is git-ignored, so a clean checkout never has one.
  touch "$DOTFILES_DIR/.env"

  run link_config_for desktop
  [ "$status" -eq 0 ]
  [ -L "$HOME/.env" ]
  [[ "$output" != *"WARNING: no .env"* ]]

  fake_home
  run link_config_for tty
  [ "$status" -eq 0 ]
  [ -L "$HOME/.env" ]
}

@test "never symlinks the committed .env.example template" {
  run link_config_for desktop
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.env.example" ]
}

@test "symlinks every config/zsh/*.zsh into ZSH_CUSTOM when oh-my-zsh is installed" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  run link_config_for tty
  [ "$status" -eq 0 ]

  # Symlinks back to the repo, so editing a copy takes effect without a re-run.
  for f in "$REPO_DIR"/config/zsh/*.zsh; do
    target="$HOME/.oh-my-zsh/custom/$(basename "$f")"
    [ -L "$target" ]
    [ "$target" -ef "$f" ]
  done

  # And not as a directory symlink -- oh-my-zsh only sources the files.
  [ ! -e "$HOME/.config/zsh" ]
}

@test "replaces a stale zsh custom symlink instead of erroring" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  ln -s /nonexistent/custom.zsh "$HOME/.oh-my-zsh/custom/custom.zsh"

  run link_config_for desktop
  [ "$status" -eq 0 ]
  [ "$HOME/.oh-my-zsh/custom/custom.zsh" -ef "$REPO_DIR/config/zsh/custom.zsh" ]
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run link_config_for desktop
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]

  # Creating it here would make install-zsh think oh-my-zsh is already
  # installed and skip itself.
  [ ! -d "$HOME/.oh-my-zsh" ]
}
