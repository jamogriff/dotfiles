#!/usr/bin/env bash
#
# Sourced by src/install-nvim, src/install-fonts, src/install-kitty and
# src/install-version-managers; not runnable on its own. Expects the caller
# to have set $DOTFILES_DIR to the repo root.
#
# Single source of truth for pinned upstream versions. Bumping a pin here
# only changes what the next bootstrap (or standalone re-run of the one
# affected script) installs — it doesn't touch an already-provisioned box.

# Neovim AppImage — https://github.com/neovim/neovim/releases
NVIM_VERSION=v0.12.5

# IBM Plex Mono Nerd Font — https://github.com/ryanoasis/nerd-fonts/releases
FONT_VERSION=v3.4.0

# kitty terminal — https://sw.kovidgoyal.net/kitty/changelog.html
KITTY_VERSION=0.48.2

# nvm's own installer script, not the Node it goes on to install.
NVM_INSTALLER_VERSION=v0.40.7

# uv's own installer script, not the Python it goes on to install.
UV_INSTALLER_VERSION=0.12.9

# Node — nvm resolves this to the latest 24.x
NODE_VERSION=24

# Python — uv resolves this to the latest 3.14.x
PYTHON_VERSION=3.14
