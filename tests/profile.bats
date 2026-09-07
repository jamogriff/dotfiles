#!/usr/bin/env bats
# src/lib/profile.bash in isolation: where DOTFILES_PROFILE comes from, and
# what happens when it doesn't come from anywhere.

load test_helper

setup() {
  export REPO_DIR
  # An empty stand-in repo root, so only the .env a test writes is ever found.
  export DOTFILES_DIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$DOTFILES_DIR"
}

# A fresh shell each time: resolve_profile exports into its caller, so reusing
# this one would leak the previous case's answer.
resolve() {
  env -u DOTFILES_PROFILE "$@" bash -c \
    'source "$REPO_DIR/src/lib/profile.bash" && resolve_profile && echo "$DOTFILES_PROFILE"'
}

@test "uses DOTFILES_PROFILE from the environment" {
  run resolve DOTFILES_PROFILE=tty
  [ "$status" -eq 0 ]
  [ "$output" = "tty" ]
}

@test "falls back to .env when the environment has nothing" {
  echo 'export DOTFILES_PROFILE=desktop' > "$DOTFILES_DIR/.env"
  run resolve
  [ "$status" -eq 0 ]
  [ "$output" = "desktop" ]
}

@test "the environment wins over .env, so a one-shot override works" {
  echo 'export DOTFILES_PROFILE=desktop' > "$DOTFILES_DIR/.env"
  run resolve DOTFILES_PROFILE=tty
  [ "$status" -eq 0 ]
  [ "$output" = "tty" ]
}

@test "fails when neither the environment nor .env sets it" {
  run resolve
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTFILES_PROFILE is unset"* ]]
  [[ "$output" == *".env.example"* ]]
}

@test "fails when .env exists but says nothing about the profile" {
  echo 'export INTELEPHENSE_LICENSE=' > "$DOTFILES_DIR/.env"
  run resolve
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTFILES_PROFILE is unset"* ]]
}

@test "fails on a value that isn't desktop or tty, echoing it back" {
  run resolve DOTFILES_PROFILE=laptop
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTFILES_PROFILE is 'laptop'"* ]]
}
