#!/usr/bin/env bats
# Tests for the top-level `dotfiles` dispatcher's own argument-handling logic
# -- the paths that don't need to reach a real install script.

load test_helper

setup() {
  DISPATCHER="$REPO_DIR/dotfiles"
}

@test "no arguments prints usage and exits 0" {
  # `run` executes the command, captures its exit code into $status and its
  # combined stdout+stderr into $output -- and, unlike calling it directly,
  # does NOT let a non-zero exit code abort the test.
  run "$DISPATCHER"
  [ "$status" -eq 0 ]
  # `[[ .. == *pattern* ]]` is a glob match, not a literal string comparison.
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "help command prints the command list" {
  run "$DISPATCHER" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
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

@test "install config with a bad target exits 1" {
  run "$DISPATCHER" install config bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"target must be 'desktop' or 'tty'"* ]]
}

@test "setup with a bad target exits 1" {
  run "$DISPATCHER" setup bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"target must be 'desktop' or 'tty'"* ]]
}

@test "install nvim routes to install-nvim (via fixture override)" {
  # DOTFILES_DIR is overridable, so point it at a fixtures dir containing a
  # fake install-nvim instead of the real one -- the real one downloads and
  # extracts an actual AppImage, which has no place in a unit test.
  DOTFILES_DIR="$REPO_DIR/tests/fixtures" run "$DISPATCHER" install nvim
  [ "$status" -eq 0 ]
  [[ "$output" == *"fake nvim installed"* ]]
}
