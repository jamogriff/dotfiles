#!/usr/bin/env bats
# Exercises the real src/install-software. Deliberately thin: it's one apt-get
# call with no branching of its own.

load test_helper

setup() {
  use_mocks
}

@test "apt-installs zathura" {
  run bash "$REPO_DIR/src/install-software"
  [ "$status" -eq 0 ]
  grep -q "apt-get install" "$MOCK_LOG"
  for pkg in zathura zathura-pdf-poppler; do
    grep -qw "$pkg" "$MOCK_LOG"
  done
}
