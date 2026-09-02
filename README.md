# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started

These dotfiles provide setup for desktop and TTY computers (**Linux only!**). On a fresh machine, run the
scripts below **in order**.

### Desktop Computer

1. `init/install-packages` — apt-installs the [System Prereq's](#system-prereqs).
2. `init/install-zsh` — installs zsh + oh-my-zsh and switches your default shell to zsh.
3. `init/desktop/install-terminal` — installs the Kitty terminal emulator.
4. `init/desktop/install-config` — installs fonts, symlinks config files (kitty, tmux, nvim, `.secrets`), and swaps the Escape/Caps Lock keys.
   (If you want to keep your Caps Lock key: `gsettings reset org.gnome.desktop.input-sources xkb-options`.)
5. `install-nvim` — installs the Neovim binary/AppImage.
6. Launch `nvim`. On first run it bootstraps `lazy.nvim`, which installs every plugin, and
   `mason.nvim` installs the configured language servers automatically. See
   [Using lazy.nvim and mason.nvim](#using-lazynvim-and-masonnvim) below for day-to-day use.

### TTY Computer

1. `init/install-packages`
2. `init/install-zsh`
3. `init/tty/install-config` — installs TMUX config, scripts and the nvim config symlink
   (also records the `tty` profile so Neovim skips desktop-only plugins — see
   `nvim/lua/user/profile.lua`).
4. `install-nvim`
5. Launch `nvim` (same first-run plugin/LSP bootstrap as the desktop path above).

**Notes:**
- You'll likely need to set `export TERM=xterm-256color` in your `~/.zshrc` file.
- Highly recommend adding the `git`, `docker` and `docker-compose` oh-my-zsh plugins to `~/.zshrc`.


## System Prereq's
`init/install-packages` apt-installs a small set of packages needed for a functional dev experience,
then installs [nvm](https://github.com/nvm-sh/nvm) (Node), [rbenv](https://rbenv.org) (Ruby),
[uv](https://docs.astral.sh/uv) (Python) and [phpenv](https://github.com/phpenv/phpenv-installer)
(PHP, with the `php-build` plugin) — each installer is safe to re-run later to update itself.

Language servers are installed by Neovim's `mason.nvim` and manages them automatically (see
`nvim/lua/user/plugins.lua`'s `ensure_installed` list). Mason still relies on the underlying
language runtime being on your `$PATH` for some servers (e.g. Node for the JS/TS/HTML/CSS
servers, Python for `zuban`, Ruby/gem for `ruby-lsp`) — `install-packages` covers that, but you
still need to actually install a Node/Ruby/Python/PHP version through nvm/rbenv/uv/phpenv
yourself (e.g. `nvm install --lts`, `rbenv install 3.3.5`, `uv python install`,
`phpenv install 8.3.x`) before mason can use it.

## Using lazy.nvim and mason.nvim

Plugins are managed by [lazy.nvim](https://lazy.folke.io), configured in
`nvim/lua/user/plugins.lua` and bootstrapped by `nvim/lua/user/lazy.lua`. Language servers are
managed by [mason.nvim](https://mason-registry.dev), configured via the `ensure_installed` list
on the `mason-lspconfig.nvim` entry in that same file.

### lazy.nvim

- `:Lazy` — open the plugin manager UI (install/update/clean status for everything).
- `:Lazy update` — install the latest version of every plugin matching its pin. Every plugin
  defaults to `version = "*"` (latest stable semver tag, when a plugin publishes one;
  otherwise its tracked branch's latest commit) via `defaults.version` in `lazy.lua`.
- `:Lazy sync` — install + clean + update in one pass; run this after adding/removing an entry
  in `plugins.lua`.
- `:Lazy restore` — reset every plugin to the exact commit recorded in `nvim/lazy-lock.json`
  (tracked in git) — use this to reproduce the same plugin versions on another machine.
- `:Lazy check` — check for updates without installing anything.
- `:checkhealth lazy` — sanity-check the install; also flags leftover files from a previous
  plugin manager (this is how the packer → lazy migration was verified).

To add a plugin: add an entry to the list in `plugins.lua` (desktop-only plugins go in the
`if not profile.is_tty() then ... end` block near the bottom) and run `:Lazy sync`.

### mason.nvim

- `:Mason` — open the tool manager UI to browse/install/uninstall/update servers by hand.
- `:MasonInstall <name>` / `:MasonUninstall <name>` — install/remove one server ad hoc, without
  touching `ensure_installed`.
- `:MasonUpdate` — refresh mason's package registry index (run this if a package you expect
  isn't found).
- `:MasonLog` — see install/runtime logs for a server that's failing (e.g. the `sqlls` issue
  noted in TODO).

To add a language server permanently: add its **lspconfig server name** — not the mason
package name, they sometimes differ (e.g. mason's `html-lsp` package is lspconfig's `html`;
check https://mason-registry.dev/registry/list if unsure) — to the `ensure_installed` list on
`mason-lspconfig.nvim` in `plugins.lua`, then either:
- add the same name to the `vim.lsp.enable({...})` call in `lua/user/plugins/lspconfig.lua`, or
- if it needs custom settings (like `intelephense`'s license key), call
  `vim.lsp.config('name', { ... })` first, then `vim.lsp.enable('name')`.

Mason installs into its own directory (`~/.local/share/nvim/mason`), independent of whatever
Node/Python/Ruby version your own version manager currently has active — it just needs *some*
working runtime for each language on `$PATH` at install time (see
[System Prereq's](#system-prereqs)).

## PHP Stuff

If you're intending on using PHP, `intelephense` is installed automatically by mason — you just
need to place your license key in `~/.secrets/` (as `INTELEPHENSE_LICENSE`).

## TODO
- Investigate a Ruby-version-manager-agnostic way to smoke-test that `ruby-lsp`'s gem install
  actually succeeds on a fresh machine (it depends on a system Ruby/gem being present).
- No SQL LSP is enabled: mason's `sqlls` (`sql-language-server@1.7.1`, the latest release)
  crashes on startup with `ERR_PACKAGE_PATH_NOT_EXPORTED`, a bug in its own
  `vscode-languageserver-protocol` dependency. Revisit once upstream publishes a fix, or try
  the Go-based `sqls` instead (needs a Go toolchain, which this repo doesn't set up).

