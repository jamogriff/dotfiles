#!/usr/bin/env bats
# The dispatcher's own argument handling and the bootstrap sequence. Pointing
# DOTFILES_DIR at tests/fixtures swaps every src/ script for a fake that just
# prints its own name, so a bootstrap is fully observable from stdout.

load test_helper

setup() {
  DISPATCHER="$REPO_DIR/dotfiles"
  fake_home
  export DOTFILES_DIR="$REPO_DIR/tests/fixtures"
}

@test "no arguments prints usage and exits 0" {
  run "$DISPATCHER"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "unknown command exits 1 and prints usage" {
  run "$DISPATCHER" bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command: 'bogus'"* ]]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "lib is not a command, even though src/lib exists" {
  run "$DISPATCHER" lib
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command: 'lib'"* ]]
}

@test "a script name runs that script from src/" {
  DOTFILES_PROFILE=desktop run "$DISPATCHER" install-docker
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake install-docker"* ]]
}

@test "bootstrap exits 1 before running anything when the profile is unset" {
  run env -u DOTFILES_PROFILE "$DISPATCHER" bootstrap
  [ "$status" -eq 1 ]
  [[ "$output" == *"DOTFILES_PROFILE is unset"* ]]
  [[ "$output" != *"fake"* ]]
}

@test "bootstrap exits 1 before running anything on an unrecognized profile" {
  DOTFILES_PROFILE=laptop run "$DISPATCHER" bootstrap
  [ "$status" -eq 1 ]
  [[ "$output" == *"DOTFILES_PROFILE is 'laptop'"* ]]
  [[ "$output" != *"fake"* ]]
}

@test "bootstrap desktop runs every step in order" {
  DOTFILES_PROFILE=desktop run "$DISPATCHER" bootstrap
  [ "$status" -eq 0 ]

  # grep -o to compare the sequence, not just membership: order is what stops
  # link-config running before install-zsh has created ~/.oh-my-zsh.
  [ "$(echo "$output" | grep -o '^fake .*' | sed 's/^fake //' | tr '\n' ' ')" \
    = "install-packages install-zsh install-version-managers install-kitty install-fonts install-nvim install-docker link-config " ]
  [[ "$output" == *"desktop bootstrap complete"* ]]
}

@test "bootstrap tty skips the desktop-only steps" {
  DOTFILES_PROFILE=tty run "$DISPATCHER" bootstrap
  [ "$status" -eq 0 ]

  [ "$(echo "$output" | grep -o '^fake .*' | sed 's/^fake //' | tr '\n' ' ')" \
    = "install-zsh install-nvim install-docker link-config " ]
  [[ "$output" != *"fake install-fonts"* ]]
  [[ "$output" == *"tty bootstrap complete"* ]]
}

@test "an exported profile beats whatever .env says" {
  echo 'export DOTFILES_PROFILE=desktop' > "$DOTFILES_DIR/.env"
  DOTFILES_PROFILE=tty run "$DISPATCHER" bootstrap
  rm -f "$DOTFILES_DIR/.env"

  [ "$status" -eq 0 ]
  [[ "$output" == *"tty bootstrap complete"* ]]
}
