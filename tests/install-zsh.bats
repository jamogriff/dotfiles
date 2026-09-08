#!/usr/bin/env bats
# Exercises the real src/install-zsh with apt-get/sudo/curl/getent/chsh mocked out.
# Not covered: the login-shell switch, which reads account state (passwd,
# /etc/shells) that isn't safe to fake convincingly -- see the getent mock.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "installs the zsh package when not already on PATH" {
  PATH="$(path_without zsh)" run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  grep -q "apt-get install -y zsh" "$MOCK_LOG"
}

@test "skips installing the zsh package when already on PATH" {
  # A fake zsh binary so `command -v zsh` succeeds without one being installed.
  mkdir -p "$BATS_TEST_TMPDIR/fakezsh"
  touch "$BATS_TEST_TMPDIR/fakezsh/zsh"
  chmod +x "$BATS_TEST_TMPDIR/fakezsh/zsh"
  PATH="$BATS_TEST_TMPDIR/fakezsh:$PATH" run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  ! grep -q "apt-get install" "$MOCK_LOG"
}

@test "runs the oh-my-zsh installer when ~/.oh-my-zsh is absent" {
  run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  grep -q "ohmyzsh" "$MOCK_LOG"
}

@test "skips the oh-my-zsh installer when ~/.oh-my-zsh already exists" {
  mkdir -p "$HOME/.oh-my-zsh"
  run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed at ~/.oh-my-zsh, skipping."* ]]
  ! grep -q "ohmyzsh" "$MOCK_LOG"
}

@test "lets the oh-my-zsh installer write ~/.zshrc from its own template" {
  run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  grep -qF 'source $ZSH/oh-my-zsh.sh' "$HOME/.zshrc"
}

@test "runs the oh-my-zsh installer without KEEP_ZSHRC" {
  run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  ! grep -q 'KEEP_ZSHRC' "$MOCK_LOG"
}

@test "does not re-run the oh-my-zsh installer, or touch ~/.zshrc again, on a second run" {
  bash "$REPO_DIR/src/install-zsh"
  local before
  before="$(cat "$HOME/.zshrc")"

  run bash "$REPO_DIR/src/install-zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed at ~/.oh-my-zsh, skipping."* ]]
  [ "$(cat "$HOME/.zshrc")" = "$before" ]
}
