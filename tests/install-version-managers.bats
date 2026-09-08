#!/usr/bin/env bats
# Exercises the real src/install-version-managers with apt-get/sudo/curl mocked
# out and fake nvm.sh/rbenv/uv fixtures, so it never hits the package manager or
# the network. What's under test is the "is this version already installed"
# branching, not the vendors' own installers.

load test_helper

setup() {
  fake_home
  use_mocks

  # The script addresses all three by absolute path, so the fakes have to sit
  # at exactly those locations.
  mkdir -p "$HOME/.nvm" "$HOME/.rbenv/bin" "$HOME/.local/bin"
  cp "$REPO_DIR/tests/fixtures/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"
  install -m 755 "$REPO_DIR/tests/fixtures/rbenv/rbenv" "$HOME/.rbenv/bin/rbenv"
  install -m 755 "$REPO_DIR/tests/fixtures/uv/uv" "$HOME/.local/bin/uv"
}

@test "apt-installs the Ruby build toolchain, so a later rbenv install works" {
  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  grep -q "apt-get install" "$MOCK_LOG"
  grep -q "build-essential" "$MOCK_LOG"
}

@test "installs Node 24 when not already present" {
  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  grep -q "nvm install 24" "$MOCK_LOG"
  grep -q "nvm alias default 24" "$MOCK_LOG"
}

@test "skips the Node install when 24 is already present" {
  # The marker our fake nvm.sh checks, as if a previous run had happened.
  touch "$HOME/.nvm/installed-24"

  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node v24.0.0 already installed, skipping."* ]]
  ! grep -q "nvm install 24" "$MOCK_LOG"
  # Set unconditionally either way -- only the install itself is guarded.
  grep -q "nvm alias default 24" "$MOCK_LOG"
}

@test "installs Python 3.14 and makes it the global default" {
  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  grep -q "uv python install 3.14 --default" "$MOCK_LOG"
  grep -q "uv python pin --global 3.14" "$MOCK_LOG"
}

@test "skips the Python install and the pin when 3.14 is already present" {
  mkdir -p "$HOME/.uv-versions"
  touch "$HOME/.uv-versions/3.14"

  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Python 3.14 already installed, skipping."* ]]
  ! grep -q "uv python" "$MOCK_LOG"
}

@test "never builds a Ruby -- that's left to the user" {
  run bash "$REPO_DIR/src/install-version-managers"
  [ "$status" -eq 0 ]
  ! grep -q "rbenv install" "$MOCK_LOG"
  ! grep -q "rbenv global" "$MOCK_LOG"
  # ...and says so, with the command to run.
  [[ "$output" == *"rbenv install 3.4.1 && rbenv global 3.4.1"* ]]
}
