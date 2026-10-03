#!/usr/bin/env bats
# Exercises the macOS branch of src/install-kitty with brew mocked out. The
# Linux branch isn't covered: it symlinks into /usr/local/bin and rewrites
# .desktop files, which there's no safe way to fake convincingly.

load test_helper

setup() {
  fake_home
  use_mocks
  export DOTFILES_OS=macos
}

@test "macos installs the kitty cask and nothing else" {
  run bash "$REPO_DIR/src/install-kitty"
  [ "$status" -eq 0 ]
  grep -q "brew install --cask kitty" "$MOCK_LOG"
  ! grep -q "sudo" "$MOCK_LOG"
  ! grep -q "curl" "$MOCK_LOG"
}

@test "macos skips the cask when brew already has it" {
  touch "$MOCK_BREW_CASKS/kitty"
  run bash "$REPO_DIR/src/install-kitty"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed by brew, skipping."* ]]
  ! grep -q "brew install" "$MOCK_LOG"
}

@test "macos leaves ~/.config/kitty alone" {
  mkdir -p "$HOME/.config/kitty"
  touch "$HOME/.config/kitty/kitty.conf"
  run bash "$REPO_DIR/src/install-kitty"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/kitty/kitty.conf" ]
}
