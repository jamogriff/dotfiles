#!/usr/bin/env bats
# Exercises the real src/install-homebrew with curl mocked out and the brew
# prefixes rooted at a scratch tree, so nothing is downloaded or installed.

load test_helper

setup() {
  fake_home
  use_mocks
  export DOTFILES_OS=macos
  export BREW_ROOT="$BATS_TEST_TMPDIR/brewroot"
}

@test "fetches and runs the official installer non-interactively when brew is absent" {
  run bash "$REPO_DIR/src/install-homebrew"
  [ "$status" -eq 0 ]
  grep -q "Homebrew/install/HEAD/install.sh" "$MOCK_LOG"
  ! grep -q "sudo" "$MOCK_LOG"
  [[ "$output" == *"Homebrew installed at $BREW_ROOT/opt/homebrew/bin/brew."* ]]
}

@test "fails when the installer finishes without leaving a brew behind" {
  # A curl that answers the installer URL with an empty script.
  mkdir -p "$BATS_TEST_TMPDIR/emptycurl"
  printf '#!/usr/bin/env bash\necho "curl $*" >> "$MOCK_LOG"\n' > "$BATS_TEST_TMPDIR/emptycurl/curl"
  chmod +x "$BATS_TEST_TMPDIR/emptycurl/curl"

  PATH="$BATS_TEST_TMPDIR/emptycurl:$PATH" run bash "$REPO_DIR/src/install-homebrew"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no brew at /opt/homebrew or /usr/local"* ]]
}

@test "skips the installer when brew already exists at a standard prefix" {
  mkdir -p "$BREW_ROOT/opt/homebrew/bin"
  printf '#!/usr/bin/env bash\n' > "$BREW_ROOT/opt/homebrew/bin/brew"
  chmod +x "$BREW_ROOT/opt/homebrew/bin/brew"

  run bash "$REPO_DIR/src/install-homebrew"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
  ! grep -q "curl" "$MOCK_LOG"
}

@test "refuses to run on debian" {
  DOTFILES_OS=debian run bash "$REPO_DIR/src/install-homebrew"
  [ "$status" -eq 1 ]
  [[ "$output" == *"only used on macOS"* ]]
  ! grep -q "curl" "$MOCK_LOG"
}
