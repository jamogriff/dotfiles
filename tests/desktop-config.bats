#!/usr/bin/env bats
# Exercises the REAL setup/desktop/config script end to end. Unlike
# setup/packages and setup/nvim it makes no network calls and installs no
# packages -- just symlinks and a font unzip -- so it's safe to run for real
# against a throwaway $HOME instead of faking it out.
#
# The symlink assertions are driven off SYNCED/NOT_SYNCED rather than being
# hand-written one per target: that's what makes "someone added config/foo and
# never wired it up" a test failure instead of a silent no-op.

load test_helper

# Every name under config/ this profile is expected to symlink via link_config.
SYNCED=".gitconfig .ideavimrc .tmux.conf kitty nvim"

# ...and every name under config/ it deliberately doesn't. `zsh` is the one real
# exception to the naming convention -- oh-my-zsh wants each .zsh file symlinked
# into $ZSH_CUSTOM individually, not the directory as a unit -- so it's covered
# by its own tests further down instead.
NOT_SYNCED="zsh"

setup() {
  fake_home
  use_mocks
}

@test "symlinks every config/ entry this profile syncs to its convention path" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  for name in $SYNCED; do
    assert_linked "$name"
  done
}

@test "every entry in config/ is either synced or deliberately skipped" {
  assert_all_entries_accounted_for "$SYNCED" "$NOT_SYNCED"
}

@test "symlinks scripts/t into ~/.local/bin" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  [ -L "$HOME/.local/bin/t" ]
  [ "$HOME/.local/bin/t" -ef "$REPO_DIR/scripts/t" ]
}

@test "unpacks the fonts zip into ~/.fonts" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  # Unzipped rather than symlinked: the repo tracks the vendor's .zip, so this
  # is the one thing in the script that isn't a link at all.
  [ -d "$HOME/.fonts" ]
  [ ! -L "$HOME/.fonts" ]
}

@test "replaces a real file or directory sitting at a destination path" {
  # The drift case `sync config` exists for: something clobbered a symlink with
  # a real file (or a hand-rolled ~/.config/nvim predating this repo). rm -f
  # alone wouldn't clear the directory, so this is worth pinning down.
  mkdir -p "$HOME/.config/nvim/lua"
  touch "$HOME/.config/nvim/init.lua"
  echo 'not a symlink' > "$HOME/.gitconfig"

  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  assert_linked nvim
  assert_linked .gitconfig
}

@test "is idempotent -- a second run leaves the same links, not an error" {
  bash "$REPO_DIR/setup/desktop/config"
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  for name in $SYNCED; do
    assert_linked "$name"
  done
}

@test "records the 'desktop' profile" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles-profile")" = "desktop" ]
}

@test "warns when .env is missing" {
  run bash "$REPO_DIR/setup/desktop/config"
  [[ "$output" == *"WARNING: no .env in the repo root"* ]]
  [ ! -e "$HOME/.env" ]
}

@test "symlinks .env to ~/.env when present" {
  # .env is git-ignored, so a clean checkout never has one -- create it for the
  # duration of this test only.
  touch "$REPO_DIR/.env"
  run bash "$REPO_DIR/setup/desktop/config"
  rm -f "$REPO_DIR/.env"   # clean up so we don't leave repo state dirty

  [ "$status" -eq 0 ]
  [ -L "$HOME/.env" ]
  [[ "$output" != *"WARNING: no .env"* ]]
}

@test "never symlinks the committed .env.example template" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.env.example" ]
}

@test "symlinks every config/zsh/*.zsh into ZSH_CUSTOM when oh-my-zsh is installed" {
  mkdir -p "$HOME/.oh-my-zsh/custom"
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]

  # Every file in config/zsh/ should land in custom/ as a symlink back to it, so
  # editing the repo copy takes effect without re-running this script.
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
  ln -s /nonexistent/aliases.zsh "$HOME/.oh-my-zsh/custom/aliases.zsh"

  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ "$HOME/.oh-my-zsh/custom/aliases.zsh" -ef "$REPO_DIR/config/zsh/aliases.zsh" ]
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]

  # Creating the dir here would make setup/zsh think oh-my-zsh is already
  # installed and skip it entirely -- the exact trap this guard exists to avoid.
  [ ! -d "$HOME/.oh-my-zsh" ]
}
