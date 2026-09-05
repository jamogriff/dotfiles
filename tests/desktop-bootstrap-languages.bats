#!/usr/bin/env bats
# Exercises the REAL setup/desktop/bootstrap-languages, but with apt-get/sudo/
# curl mocked out (see tests/mocks/) and fake nvm.sh/rbenv fixtures standing
# in for the real ones, so this never touches the system package manager, the
# network, or actually compiles Ruby from source.
#
# What's under test is the idempotency logic -- "is this version already
# installed" -- since that's the part with actual branching behavior. Whether
# the real nvm/rbenv/uv installer scripts themselves work isn't something a
# unit test here can verify; that's on nvm/rbenv/uv's own test suites.

load test_helper

setup() {
  fake_home
  use_mocks

  # bootstrap-languages sources "$HOME/.nvm/nvm.sh" and calls
  # "$HOME/.rbenv/bin/rbenv" by absolute path, so the fakes have to live at
  # those exact locations for the real script to find them.
  mkdir -p "$HOME/.nvm" "$HOME/.rbenv/bin"
  cp "$REPO_DIR/tests/fixtures/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"
  cp "$REPO_DIR/tests/fixtures/rbenv/rbenv" "$HOME/.rbenv/bin/rbenv"
  chmod +x "$HOME/.rbenv/bin/rbenv"
}

@test "apt-installs the Ruby build toolchain" {
  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  grep -q "apt-get install" "$MOCK_LOG"
  grep -q "build-essential" "$MOCK_LOG"
}

@test "installs Node 24 when not already present" {
  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  grep -q "nvm install 24" "$MOCK_LOG"
  grep -q "nvm alias default 24" "$MOCK_LOG"
}

@test "skips the Node install when 24 is already present" {
  # Pre-seed the marker our fake nvm.sh checks, as if a previous run (or a
  # manual `nvm install 24`) had already happened.
  touch "$HOME/.nvm/installed-24"

  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node v24.0.0 already installed, skipping."* ]]
  ! grep -q "nvm install 24" "$MOCK_LOG"
  # The default alias is set unconditionally either way -- only the install
  # itself is guarded.
  grep -q "nvm alias default 24" "$MOCK_LOG"
}

@test "installs Ruby 3.3.5 when not already present" {
  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  grep -q "rbenv install 3.3.5" "$MOCK_LOG"
  grep -q "rbenv global 3.3.5" "$MOCK_LOG"
}

@test "skips the Ruby install when 3.3.5 is already present" {
  mkdir -p "$HOME/.rbenv/versions"
  touch "$HOME/.rbenv/versions/3.3.5"

  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Ruby 3.3.5 already installed, skipping."* ]]
  ! grep -q "rbenv install 3.3.5" "$MOCK_LOG"
  grep -q "rbenv global 3.3.5" "$MOCK_LOG"
}
