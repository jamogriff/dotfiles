#!/usr/bin/env bats
# Exercises the real src/install-nvim with curl mocked out, so no AppImage or
# tree-sitter binary is ever downloaded. The mock leaves behind stand-ins that
# answer --appimage-extract / --version the way the real ones do, which is all
# the script uses.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "downloads the AppImage and symlinks the extracted AppRun to nvim" {
  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]

  grep -q "nvim-linux-x86_64.appimage" "$MOCK_LOG"
  [ -L "$HOME/.local/bin/nvim" ]
  [ "$HOME/.local/bin/nvim" -ef "$HOME/.local/nvim-app/AppRun" ]
}

@test "apt-installs curl when it isn't already on PATH" {
  # bootstrap doesn't run install-packages on tty, so this is the only thing
  # that puts curl there.
  PATH="$(path_without curl)" run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  grep -q "apt-get install -y curl" "$MOCK_LOG"
}

@test "does not apt-install curl when it is already on PATH" {
  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  ! grep -q "apt-get" "$MOCK_LOG"
}

@test "skips the download when the pinned version is already installed" {
  bash "$REPO_DIR/src/install-nvim"
  : > "$MOCK_LOG"

  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed, skipping."* ]]
  [ ! -s "$MOCK_LOG" ]
}

@test "replaces an install of a different version" {
  mkdir -p "$HOME/.local/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.9.0"\n' > "$HOME/.local/bin/nvim"
  chmod +x "$HOME/.local/bin/nvim"

  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  [ "$HOME/.local/bin/nvim" -ef "$HOME/.local/nvim-app/AppRun" ]
}

@test "installs the tree-sitter CLI into ~/.local/bin" {
  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]

  grep -q "tree-sitter-linux-x64.gz" "$MOCK_LOG"
  [ -x "$HOME/.local/bin/tree-sitter" ]
  [[ "$("$HOME/.local/bin/tree-sitter" --version)" == "tree-sitter 0.27.0" ]]
}

@test "installs tree-sitter even when the pinned Neovim is already there" {
  bash "$REPO_DIR/src/install-nvim"
  rm "$HOME/.local/bin/tree-sitter"
  : > "$MOCK_LOG"

  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  grep -q "tree-sitter-linux-x64.gz" "$MOCK_LOG"
  ! grep -q "appimage" "$MOCK_LOG"
  [ -x "$HOME/.local/bin/tree-sitter" ]
}

@test "replaces a tree-sitter of a different version" {
  mkdir -p "$HOME/.local/bin"
  printf '#!/usr/bin/env bash\necho "tree-sitter 0.22.6"\n' > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"

  run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  [[ "$("$HOME/.local/bin/tree-sitter" --version)" == "tree-sitter 0.27.0" ]]
}

@test "macos brew-installs neovim and the tree-sitter CLI, nothing from GitHub" {
  DOTFILES_OS=macos run bash "$REPO_DIR/src/install-nvim"
  [ "$status" -eq 0 ]
  grep -q "brew install neovim tree-sitter-cli" "$MOCK_LOG"
  ! grep -q "curl" "$MOCK_LOG"
  ! grep -q "apt-get" "$MOCK_LOG"
  [ ! -e "$HOME/.local/bin/nvim" ]
}
