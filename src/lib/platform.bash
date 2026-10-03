#!/usr/bin/env bash
#
# Sourced by the dispatcher, src/lib/profile.bash and every src/ script that
# branches on OS; not runnable on its own.

# Resolve and export DOTFILES_OS: 'debian' (any Debian-family Linux) or
# 'macos'. Detected from uname, never configured — an already-exported value
# only exists so the test suite can force a branch on the other OS.
resolve_os() {
  if [ -z "${DOTFILES_OS:-}" ]; then
    case "$(uname -s)" in
      Darwin) DOTFILES_OS=macos ;;
      Linux)  DOTFILES_OS=debian ;;
      *)
        echo "Unsupported OS '$(uname -s)': this repo targets Debian-family Linux and macOS." >&2
        return 1
        ;;
    esac
  fi

  case "$DOTFILES_OS" in
    debian|macos)
      export DOTFILES_OS
      ;;
    *)
      echo "DOTFILES_OS is '$DOTFILES_OS', which isn't 'debian' or 'macos'." >&2
      return 1
      ;;
  esac
}

# Print the brew binary at whichever standard prefix has one: /opt/homebrew
# on Apple Silicon, /usr/local on Intel. $BREW_ROOT is only for the test
# suite, which plants a fake under a scratch tree.
find_brew() {
  local prefix
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "${BREW_ROOT:-}$prefix/bin/brew" ]; then
      echo "${BREW_ROOT:-}$prefix/bin/brew"
      return 0
    fi
  done
  return 1
}

# Each bootstrap step runs in a fresh bash, so the PATH install-homebrew left
# behind is gone by the time the next step wants `brew`.
ensure_brew_on_path() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  local brew
  brew="$(find_brew)" || {
    echo "Homebrew isn't installed at /opt/homebrew or /usr/local. Run 'dotfiles install-homebrew' first." >&2
    return 1
  }
  eval "$("$brew" shellenv)"
}

# Install OS packages with whichever package manager this OS has.
pkg_install() {
  case "$DOTFILES_OS" in
    debian)
      sudo apt-get update
      sudo apt-get install -y "$@"
      ;;
    macos)
      ensure_brew_on_path
      brew install "$@"
      ;;
  esac
}
