#!/usr/bin/env bats
# Exercises the real setup/packages. Deliberately thin: it's one apt-get call
# with no branching of its own.

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
