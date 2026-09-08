#!/usr/bin/env bash
# Stand-in for oh-my-zsh's real tools/install.sh. tests/mocks/curl prints this
# for the oh-my-zsh install URL, and install-zsh pipes it straight into `sh -c`,
# so it runs with install-zsh's own environment -- including $HOME and
# $MOCK_LOG. Mirrors the two side effects the tests depend on: creating
# ~/.oh-my-zsh (what install-zsh's own guard checks for) and writing ~/.zshrc
# from the vendor's stock template.
mkdir -p "$HOME/.oh-my-zsh"

if [ -n "${KEEP_ZSHRC:-}" ]; then
  echo "KEEP_ZSHRC=$KEEP_ZSHRC" >> "$MOCK_LOG"
fi

cat > "$HOME/.zshrc" <<'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh
ZSHRC
