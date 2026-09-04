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
  export PATH="$REPO_DIR/tests/mocks:$PATH"
  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MOCK_LOG"
}
