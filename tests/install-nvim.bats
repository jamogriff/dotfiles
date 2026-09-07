#!/usr/bin/env bats
# Exercises the real src/install-nvim with curl mocked out, so no AppImage is
# ever downloaded. The mock leaves behind a stand-in that answers
# --appimage-extract the way the real one does, which is all the script uses.

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
