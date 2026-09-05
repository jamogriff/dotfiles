#!/usr/bin/env bats
# Tests for the top-level `dotfiles` dispatcher's own argument-handling logic
# -- the paths that don't need to reach a real install script.

load test_helper

setup() {
  DISPATCHER="$REPO_DIR/dotfiles"
}

@test "no arguments prints usage and exits 0" {
  run "$DISPATCHER"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "help command prints both bootstrap and install sections" {
  run "$DISPATCHER" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bootstrap (one-time"* ]]
  [[ "$output" == *"Install (piecewise"* ]]
}

@test "unknown command exits 1" {
  run "$DISPATCHER" bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command: 'bogus'"* ]]
}

@test "unknown install target exits 1" {
  run "$DISPATCHER" install bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown install target: 'bogus'"* ]]
}

@test "unknown bootstrap target exits 1" {
  run "$DISPATCHER" bootstrap bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown bootstrap target: 'bogus'"* ]]
}

@test "install config with a bad target exits 1" {
  run "$DISPATCHER" install config bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"target must be 'desktop' or 'tty'"* ]]
}

@test "bootstrap tty does not run desktop-only steps (via fixture override)" {
  # DOTFILES_DIR is overridable, so point it at fixtures containing fakes for
  # every step `bootstrap tty` should call, and NONE of the desktop-only
  # ones (bootstrap-languages, terminal) -- if the dispatcher tried to call a
  # desktop-only step for the tty target, bash itself would fail with "No
  # such file or directory" trying to run a fixture that doesn't exist.
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" bootstrap tty
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake packages installed"* ]]
  [[ "$output" == *"fake zsh installed"* ]]
  [[ "$output" == *"fake tty config installed"* ]]
  [[ "$output" == *"fake nvim installed"* ]]
  [[ "$output" == *"tty bootstrap complete"* ]]
}

@test "bootstrap desktop runs every step including languages and terminal (via fixture override)" {
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" bootstrap desktop
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake packages installed"* ]]
  [[ "$output" == *"fake zsh installed"* ]]
  [[ "$output" == *"fake languages bootstrapped"* ]]
  [[ "$output" == *"fake terminal installed"* ]]
  [[ "$output" == *"fake desktop config installed"* ]]
  [[ "$output" == *"fake nvim installed"* ]]
  [[ "$output" == *"desktop bootstrap complete"* ]]
}

@test "bootstrap languages routes to bootstrap-languages on its own (via fixture override)" {
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" bootstrap languages
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake languages bootstrapped"* ]]
  # And nothing else ran -- this is meant to be callable on its own.
  [[ "$output" != *"fake packages installed"* ]]
}

@test "install nvim routes to the real script name (via fixture override)" {
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install nvim
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake nvim installed"* ]]
}
