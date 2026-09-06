#!/usr/bin/env bats
# Exercises the real setup/desktop/bootstrap-languages with apt-get/sudo/curl
# mocked out and fake nvm.sh/rbenv fixtures, so it never hits the package
# manager, the network, or a Ruby compile. What's under test is the "is this
# version already installed" branching, not the vendors' own installers.

load test_helper

setup() {
  fake_home
  use_mocks

  # The script addresses both by absolute path, so the fakes have to sit at
  # exactly those locations.
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
  # The marker our fake nvm.sh checks, as if a previous run had happened.
  touch "$HOME/.nvm/installed-24"

  run bash "$REPO_DIR/setup/desktop/bootstrap-languages"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node v24.0.0 already installed, skipping."* ]]
  ! grep -q "nvm install 24" "$MOCK_LOG"
  # Set unconditionally either way -- only the install itself is guarded.
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
