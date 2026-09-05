#!/usr/bin/env bash
# Shared setup, loaded at the top of every .bats file with `load test_helper`.

# Absolute path to the repo root, no matter where `bats` is invoked from.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Give each test its own throwaway $HOME so scripts that write dotfiles
# (symlinks, .dotfiles-profile, .zshrc edits) never touch the real one.
# $BATS_TEST_TMPDIR is created fresh by bats before each test and deleted after.
fake_home() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
}

# Prepend a directory of fake binaries to $PATH so calls to tools that are
# either destructive (apt-get, sudo) or environment-specific (gsettings,
# chsh) resolve to no-op stand-ins instead of the real thing.
use_mocks() {
  # MOCK_BIN_DIR is scratch space *mocks themselves* can write into at test
  # run time (e.g. apt-get faking up a zsh binary once "installed") -- unlike
  # tests/mocks/, which is static, checked-in, and shared across every test.
  # It's prepended ahead of tests/mocks/ so anything a mock plants here is
  # found first.
  export MOCK_BIN_DIR="$BATS_TEST_TMPDIR/mockbin"
  mkdir -p "$MOCK_BIN_DIR"
  export PATH="$MOCK_BIN_DIR:$REPO_DIR/tests/mocks:$PATH"
  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MOCK_LOG"
}
