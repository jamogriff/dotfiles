#!/usr/bin/env bats
# Exercises the real src/install-fonts with curl, unzip and fc-cache mocked
# out, so nothing is downloaded and the host's font cache is left alone.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "downloads the pinned release to a temp dir and unpacks only the Mono faces" {
  run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]

  grep -qF "nerd-fonts/releases/download/v3.4.0/IBMPlexMono.zip" "$MOCK_LOG"
  grep -qF "BlexMonoNerdFontMono-*.ttf" "$MOCK_LOG"
  grep -qF "fc-cache" "$MOCK_LOG"
  [ -f "$HOME/.fonts/BlexMonoNerdFontMono-Regular.ttf" ]

  # The whole point of the rewrite: the archive never lands in the checkout.
  ! grep -qF "$REPO_DIR" "$MOCK_LOG"
}

@test "skips everything when the pinned version is already installed" {
  bash "$REPO_DIR/src/install-fonts"
  : > "$MOCK_LOG"

  run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed, skipping."* ]]
  [ ! -s "$MOCK_LOG" ]
}

@test "wipes the differently-named faces a pre-v3 machine has in ~/.fonts" {
  mkdir -p "$HOME/.fonts"
  touch "$HOME/.fonts/Blex Mono Nerd Font Complete Mono.ttf"

  run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.fonts/Blex Mono Nerd Font Complete Mono.ttf" ]
  [ -f "$HOME/.fonts/BlexMonoNerdFontMono-Regular.ttf" ]
}

@test "reinstalls when the installed version isn't the pinned one" {
  bash "$REPO_DIR/src/install-fonts"
  echo v3.0.0 > "$HOME/.fonts/.nerd-font-version"
  : > "$MOCK_LOG"

  run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  grep -qF "IBMPlexMono.zip" "$MOCK_LOG"
}

@test "macos installs the font cask and never downloads or wipes a font dir" {
  mkdir -p "$HOME/.fonts" "$HOME/Library/Fonts"
  touch "$HOME/.fonts/keep.ttf" "$HOME/Library/Fonts/Other.ttf"

  DOTFILES_OS=macos run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  grep -q "brew install --cask font-blex-mono-nerd-font" "$MOCK_LOG"
  ! grep -q "curl" "$MOCK_LOG"
  ! grep -q "unzip" "$MOCK_LOG"
  ! grep -q "fc-cache" "$MOCK_LOG"
  [ -f "$HOME/.fonts/keep.ttf" ]
  [ -f "$HOME/Library/Fonts/Other.ttf" ]
  [[ "$output" == *"installed to ~/Library/Fonts"* ]]
}

@test "macos skips the cask when brew already has it" {
  touch "$MOCK_BREW_CASKS/font-blex-mono-nerd-font"
  DOTFILES_OS=macos run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed, skipping."* ]]
  ! grep -q "brew install" "$MOCK_LOG"
}

@test "macos warns when the cask left no BlexMono faces behind" {
  touch "$MOCK_BREW_CASKS/font-blex-mono-nerd-font"
  DOTFILES_OS=macos run bash "$REPO_DIR/src/install-fonts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: no BlexMonoNerdFontMono-*.ttf"* ]]
}
