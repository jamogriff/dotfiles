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

@test "install config reads the profile from ~/.dotfiles-profile" {
  fake_home
  echo tty > "$HOME/.dotfiles-profile"

  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install config
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake tty config installed"* ]]
  [[ "$output" != *"fake desktop config installed"* ]]

  echo desktop > "$HOME/.dotfiles-profile"

  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install config
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake desktop config installed"* ]]
  [[ "$output" != *"fake tty config installed"* ]]
}

@test "install config exits 1 when the machine has no profile marker" {
  fake_home

  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install config
  [ "$status" -eq 1 ]
  [[ "$output" == *"hasn't been bootstrapped yet"* ]]
}

@test "install config exits 1 on an unrecognized profile marker" {
  fake_home
  echo bogus > "$HOME/.dotfiles-profile"

  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install config
  [ "$status" -eq 1 ]
  [[ "$output" == *"isn't 'desktop' or 'tty'"* ]]
}

@test "install config rejects a target argument rather than ignoring it" {
  fake_home
  echo tty > "$HOME/.dotfiles-profile"

  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install config desktop
  [ "$status" -eq 1 ]
  [[ "$output" == *"takes no target"* ]]
  # And nothing was applied on the way out.
  [[ "$output" != *"fake tty config installed"* ]]
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

@test "bootstrap languages is not a command; it only runs inside bootstrap desktop" {
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" bootstrap languages
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown bootstrap target: 'languages'"* ]]
  [[ "$output" != *"fake languages bootstrapped"* ]]
}

@test "install nvim routes to the real script name (via fixture override)" {
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install nvim
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake nvim installed"* ]]
}
