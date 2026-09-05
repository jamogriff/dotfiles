#!/usr/bin/env bash
# Fake nvm for tests. install-packages sources this exactly like the real
# ~/.nvm/nvm.sh and calls `nvm version`/`nvm install`/`nvm alias` on it -- so
# this defines the same three subcommands, backed by a marker file per
# "installed" version instead of an actual Node download.
nvm() {
  local sub="$1"; shift
  case "$sub" in
    version)
      local v="$1"
      if [ -e "$NVM_DIR/installed-$v" ]; then
        echo "v$v.0.0"
      else
        echo "N/A"
      fi
      ;;
    install)
      local v="$1"
      touch "$NVM_DIR/installed-$v"
      echo "nvm install $v" >> "$MOCK_LOG"
      ;;
    alias)
      echo "nvm alias $*" >> "$MOCK_LOG"
      ;;
  esac
}
