#!/usr/bin/env bats
# Exercises the real setup/desktop/config end to end -- just symlinks and a
# font unzip, so safe to run against a throwaway $HOME.
#
# Assertions are driven off SYNCED/NOT_SYNCED rather than hand-written per
# target: that's what makes an unwired config/ entry a failure, not a no-op.

load test_helper

# Every name under config/ this profile is expected to symlink.
SYNCED=".gitconfig .ideavimrc .tmux.conf kitty nvim"

# ...and every name it deliberately doesn't. `zsh` goes into $ZSH_CUSTOM file
# by file instead, covered by its own tests further down.
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

  # Unzipped rather than symlinked -- the one thing here that isn't a link.
  [ -d "$HOME/.fonts" ]
  [ ! -L "$HOME/.fonts" ]
}

@test "replaces a real file or directory sitting at a destination path" {
  # The drift case `sync config` exists for. rm -f alone wouldn't clear the
  # directory, so this is worth pinning down.
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
  # .env is git-ignored, so a clean checkout never has one.
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
  ln -s /nonexistent/aliases.zsh "$HOME/.oh-my-zsh/custom/aliases.zsh"

  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [ "$HOME/.oh-my-zsh/custom/aliases.zsh" -ef "$REPO_DIR/config/zsh/aliases.zsh" ]
}

@test "skips zsh custom symlinks, and does not create ~/.oh-my-zsh, when it is absent" {
  run bash "$REPO_DIR/setup/desktop/config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: ~/.oh-my-zsh not found"* ]]

  # Creating it here would make setup/zsh think oh-my-zsh is already installed
  # and skip itself.
  [ ! -d "$HOME/.oh-my-zsh" ]
}
