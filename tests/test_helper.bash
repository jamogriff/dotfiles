#!/usr/bin/env bash
# Shared setup, loaded at the top of every .bats file with `load test_helper`.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# A throwaway $HOME per test, so scripts that write dotfiles never touch the real
# one. $BATS_TEST_TMPDIR is created fresh before each test and deleted after.
# Cleared rather than just created, so a test that calls this twice really does
# get a second clean slate.
fake_home() {
  export HOME="$BATS_TEST_TMPDIR/home"
  rm -rf "$HOME"
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
  export MOCKS_DIR="$REPO_DIR/tests/mocks"
  export PATH="$MOCK_BIN_DIR:$MOCKS_DIR:$PATH"
  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MOCK_LOG"
}

# A throwaway repo root whose config/, scripts/ and src/ point back at the real
# ones. link-config takes $DOTFILES_DIR as its root, so this lets a
# test add or omit a .env without touching the checkout the suite is running
# from — which may well be someone's live dotfiles.
fake_repo() {
  export DOTFILES_DIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$DOTFILES_DIR"
  local dir
  for dir in config scripts src; do
    ln -sfn "$REPO_DIR/$dir" "$DOTFILES_DIR/$dir"
  done
}

# A replacement PATH built from scratch -- an allowlist of real tools plus the
# mocks, minus the one tool a test needs to be genuinely unreachable. Prepending
# mocks isn't enough: the host's own copy is still further down the inherited
# PATH, and tests/mocks may itself carry a stand-in for it.
#
# $MOCK_BIN_DIR stays in front, so a mock that plants a binary mid-run (apt-get
# "installing" what was missing) still takes effect.
path_without() {
  local missing="$1"
  local shimdir="$BATS_TEST_TMPDIR/shims-no-$missing"
  mkdir -p "$shimdir"

  local tool real
  for tool in bash sh grep sed cat cp mv mkdir rm ln touch basename dirname printf cut chmod; do
    real="$(command -v "$tool")" || continue
    ln -sf "$real" "$shimdir/$tool"
  done
  for tool in "$MOCKS_DIR"/*; do
    ln -sf "$tool" "$shimdir/$(basename "$tool")"
  done
  rm -f "$shimdir/$missing"

  echo "$MOCK_BIN_DIR:$shimdir"
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
