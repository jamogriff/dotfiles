#!/usr/bin/env bash
#
# Sourced by the dispatcher and by src/link-config; not runnable on its own.
# Expects the caller to have set $DOTFILES_DIR to the repo root.

# Resolve and export DOTFILES_PROFILE, or fail explaining what's missing.
#
# An already-exported value wins over .env so a one-shot override works:
#   DOTFILES_PROFILE=tty ./dotfiles bootstrap
resolve_profile() {
  if [ -z "${DOTFILES_PROFILE:-}" ] && [ -f "$DOTFILES_DIR/.env" ]; then
    # shellcheck disable=SC1091
    . "$DOTFILES_DIR/.env"
  fi

  case "${DOTFILES_PROFILE:-}" in
    desktop|tty)
      export DOTFILES_PROFILE
      ;;
    '')
      echo "DOTFILES_PROFILE is unset, and $DOTFILES_DIR/.env doesn't set it either. Run 'cp .env.example .env', then set DOTFILES_PROFILE to 'desktop' or 'tty'." >&2
      return 1
      ;;
    *)
      echo "DOTFILES_PROFILE is '$DOTFILES_PROFILE', which isn't 'desktop' or 'tty'." >&2
      return 1
      ;;
  esac
}
