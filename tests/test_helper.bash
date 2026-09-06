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

# For the one test that needs to prove "zsh isn't installed yet" (install-zsh's
# `if ! command -v zsh` branch): just prepending mocks isn't enough, since the
# real system zsh -- if the machine running these tests already has one, e.g.
# because you're reading this in a zsh prompt -- is still reachable further
# down the inherited $PATH. This builds a *replacement* PATH from scratch:
# symlinks to a fixed allowlist of real tools the script actually needs, plus
# the mocks, and nothing else -- so zsh is unreachable regardless of where the
# host happens to keep it, rather than relying on it coincidentally being
# absent from whatever machine happens to run the suite.
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

# --- config/ symlink assertions -------------------------------------------
# Shared by desktop-config.bats and tty-config.bats, which differ only in which
# names each profile syncs.

# Every entry in the repo's config/ directory, one per line. `ls -A` is what
# picks up the dotfiles (.gitconfig, .tmux.conf, .ideavimrc) that a plain glob
# would skip.
config_entries() {
  (cd "$REPO_DIR/config" && ls -A)
}

# Assert config/<name> got symlinked to where the naming convention says it
# should land: a directory to ~/.config/<name>, a file to ~/<name>.
#
# The rule is spelled out again here rather than reusing setup/lib/config.bash's
# link_config, so a bug in that function fails a test instead of being asserted
# against its own output.
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
  # `-ef` compares what the paths resolve to, so it passes regardless of how the
  # link spells the path it points at (the scripts use a ../.. relative form).
  if [ ! "$dest" -ef "$REPO_DIR/config/$name" ]; then
    echo "$dest does not resolve to $REPO_DIR/config/$name" >&2
    return 1
  fi
}

# The inverse: nothing was linked for a name this profile shouldn't sync.
assert_not_linked() {
  local name="$1"
  [ ! -e "$HOME/.config/$name" ] || { echo "unexpected $HOME/.config/$name" >&2; return 1; }
  [ ! -e "$HOME/$name" ] || { echo "unexpected $HOME/$name" >&2; return 1; }
}

# Guards against the failure this suite's structural tests exist to catch:
# someone adds config/<something> and forgets to add it to a profile's list, so
# it silently never gets symlinked on any machine. Every entry in config/ must
# be named by one of the two lists the calling test passes in -- the names it
# syncs, and the names it deliberately doesn't -- each as one space-separated
# string.
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
