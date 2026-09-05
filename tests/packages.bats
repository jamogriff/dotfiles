#!/usr/bin/env bats
# Exercises the REAL setup/packages -- OS-level prerequisites shared by both
# profiles. Deliberately thin: this script is now just an apt-get call, with
# no idempotency branches of its own to test (apt-get install is already a
# no-op for an already-installed package).

load test_helper

setup() {
  use_mocks
}

@test "apt-installs the shared package list" {
  run bash "$REPO_DIR/setup/packages"
  [ "$status" -eq 0 ]
  grep -q "apt-get install" "$MOCK_LOG"
  for pkg in xclip tmux curl unzip fzf ripgrep; do
    grep -qw "$pkg" "$MOCK_LOG"
  done
}

@test "does not install zsh or Ruby build deps -- those are separate steps now" {
  run bash "$REPO_DIR/setup/packages"
  [ "$status" -eq 0 ]
  ! grep -qw "zsh" "$MOCK_LOG"
  ! grep -qw "build-essential" "$MOCK_LOG"
}
