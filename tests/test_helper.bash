#!/usr/bin/env bash
# Shared setup, loaded at the top of every .bats file with `load test_helper`.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# A throwaway $HOME per test, so scripts that write dotfiles never touch the real
# one. $BATS_TEST_TMPDIR is created fresh before each test and deleted after.
fake_home() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
}

# Resolve destructive (apt-get, sudo) or environment-specific (chsh, getent)
# tools to the stand-ins in tests/mocks/.
use_mocks() {
  # Scratch space the mocks themselves write into at run time (apt-get faking up
  # a zsh binary once "installed"), ahead of the static tests/mocks/ so anything
  # planted here is found first.
  export MOCK_BIN_DIR="$BATS_TEST_TMPDIR/mockbin"
  mkdir -p "$MOCK_BIN_DIR"
  export PATH="$MOCK_BIN_DIR:$REPO_DIR/tests/mocks:$PATH"
  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MOCK_LOG"
}

# A replacement PATH built from scratch — an allowlist of real tools plus the
# mocks, nothing else — for the one test that needs zsh to be genuinely
# unreachable. Prepending mocks isn't enough: the host's own zsh is still further
# down the inherited PATH.
path_without_zsh() {
  local shimdir="$BATS_TEST_TMPDIR/shims-no-zsh"
  mkdir -p "$shimdir"
  local tool
  for tool in bash sh grep sed cat mkdir rm ln touch basename dirname printf cut chmod; do
    local real
    real="$(command -v "$tool")" || continue
    ln -sf "$real" "$shimdir/$tool"
  done
  echo "$shimdir:$MOCK_BIN_DIR:$REPO_DIR/tests/mocks"
}

# --- config/ symlink assertions, shared by the two profile suites -----------

# `ls -A` is what picks up the dotfile entries a plain glob would skip.
config_entries() {
  (cd "$REPO_DIR/config" && ls -A)
}

# Assert config/<name> landed where the naming convention says. The rule is
# spelled out again here rather than reusing link_config, so a bug in that
# function fails a test instead of being asserted against its own output.
assert_linked() {
  local name="$1" dest

  if [ -d "$REPO_DIR/config/$name" ]; then
    dest="$HOME/.config/$name"
  else
    dest="$HOME/$name"
  fi

  if [ ! -L "$dest" ]; then
    echo "expected a symlink at $dest for config/$name" >&2
    return 1
  fi
  # -ef compares what the paths resolve to, so it passes regardless of how the
  # link spells the path (the scripts use a ../.. relative form).
  if [ ! "$dest" -ef "$REPO_DIR/config/$name" ]; then
    echo "$dest does not resolve to $REPO_DIR/config/$name" >&2
    return 1
  fi
}

assert_not_linked() {
  local name="$1"
  [ ! -e "$HOME/.config/$name" ] || { echo "unexpected $HOME/.config/$name" >&2; return 1; }
  [ ! -e "$HOME/$name" ] || { echo "unexpected $HOME/$name" >&2; return 1; }
}

# Catches the silent failure: someone adds config/<something> and forgets a
# profile's list, so it never gets symlinked anywhere. Every entry must be named
# by one of the two space-separated lists the calling test passes in.
assert_all_entries_accounted_for() {
  local expected=" $1 $2 "
  local entry
  local failed=0

  while read -r entry; do
    # Space-delimited substring match, which is why both sides are padded.
    if [[ "$expected" != *" $entry "* ]]; then
      echo "config/$entry isn't in this profile's synced or deliberately-skipped list" >&2
      failed=1
    fi
  done < <(config_entries)

  return "$failed"
}
