#!/usr/bin/env bats
# src/lib/platform.bash in isolation: OS detection, the DOTFILES_OS override,
# finding brew, and which package manager pkg_install reaches for.

load test_helper

setup() {
  export REPO_DIR
  use_mocks
}

# A fresh shell with a fake uname answering $1, so the real host's kernel
# never leaks into the result.
resolve_os_on() {
  local kernel="$1"; shift
  mkdir -p "$BATS_TEST_TMPDIR/uname-bin"
  printf '#!/usr/bin/env bash\necho %s\n' "$kernel" > "$BATS_TEST_TMPDIR/uname-bin/uname"
  chmod +x "$BATS_TEST_TMPDIR/uname-bin/uname"
  PATH="$BATS_TEST_TMPDIR/uname-bin:$PATH" env -u DOTFILES_OS "$@" bash -c \
    'source "$REPO_DIR/src/lib/platform.bash" && resolve_os && echo "$DOTFILES_OS"'
}

in_platform() {
  bash -c "source \"\$REPO_DIR/src/lib/platform.bash\" && $1"
}

@test "Darwin resolves to macos" {
  run resolve_os_on Darwin
  [ "$status" -eq 0 ]
  [ "$output" = macos ]
}

@test "Linux resolves to debian" {
  run resolve_os_on Linux
  [ "$status" -eq 0 ]
  [ "$output" = debian ]
}

@test "any other kernel is refused" {
  run resolve_os_on FreeBSD
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported OS 'FreeBSD'"* ]]
}

@test "an exported DOTFILES_OS wins over uname" {
  run resolve_os_on Linux DOTFILES_OS=macos
  [ "$status" -eq 0 ]
  [ "$output" = macos ]
}

@test "an exported DOTFILES_OS that isn't debian or macos is refused" {
  run resolve_os_on Linux DOTFILES_OS=windows
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTFILES_OS is 'windows'"* ]]
}

@test "find_brew reports the Apple Silicon prefix, then the Intel one" {
  export BREW_ROOT="$BATS_TEST_TMPDIR/brewroot"
  run in_platform find_brew
  [ "$status" -ne 0 ]

  mkdir -p "$BREW_ROOT/usr/local/bin"
  printf '#!/usr/bin/env bash\n' > "$BREW_ROOT/usr/local/bin/brew"
  chmod +x "$BREW_ROOT/usr/local/bin/brew"
  run in_platform find_brew
  [ "$status" -eq 0 ]
  [ "$output" = "$BREW_ROOT/usr/local/bin/brew" ]

  mkdir -p "$BREW_ROOT/opt/homebrew/bin"
  cp "$BREW_ROOT/usr/local/bin/brew" "$BREW_ROOT/opt/homebrew/bin/brew"
  run in_platform find_brew
  [ "$output" = "$BREW_ROOT/opt/homebrew/bin/brew" ]
}

@test "ensure_brew_on_path points at install-homebrew when brew is nowhere" {
  export BREW_ROOT="$BATS_TEST_TMPDIR/brewroot"
  PATH="$(path_without brew)" run in_platform ensure_brew_on_path
  [ "$status" -ne 0 ]
  [[ "$output" == *"dotfiles install-homebrew"* ]]
}

@test "pkg_install uses apt on debian and brew on macos" {
  DOTFILES_OS=debian run in_platform 'pkg_install foo bar'
  [ "$status" -eq 0 ]
  grep -q "apt-get install -y foo bar" "$MOCK_LOG"
  ! grep -q "brew" "$MOCK_LOG"

  : > "$MOCK_LOG"
  DOTFILES_OS=macos run in_platform 'pkg_install foo bar'
  [ "$status" -eq 0 ]
  grep -q "brew install foo bar" "$MOCK_LOG"
  ! grep -q "apt-get" "$MOCK_LOG"
  ! grep -q "sudo" "$MOCK_LOG"
}
