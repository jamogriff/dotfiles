# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started

These dotfiles provide two profiles (**Linux only!**), scoped very differently on purpose:

- **Desktop** — a full dev environment. Every language runtime, LSP, and editor plugin in this
  repo is here for writing code, so desktop gets all of it.
- **TTY** — a minimal profile for servers: just zsh and nvim as a plain editor, no language
  runtimes, no LSPs, no GUI terminal. See [Script Layout](#script-layout) below for why that
  split runs all the way down into which scripts even exist for each profile.

On a fresh machine, run one bootstrap command:

### Desktop Computer

1. `./dotfiles bootstrap desktop`
2. Launch `nvim`. On first run it bootstraps `lazy.nvim`, which installs every plugin, and
   `mason.nvim` installs the configured language servers automatically. See
   [Using lazy.nvim and mason.nvim](#using-lazynvim-and-masonnvim) below for day-to-day use.

### TTY Computer

1. `./dotfiles bootstrap tty`
2. Launch `nvim` — just the editor and its core plugins; no plugin needs a language runtime to
   install, since mason/lspconfig aren't loaded on this profile at all.

**Notes:**
- You'll likely need to set `export TERM=xterm-256color` in your `~/.zshrc` file.

### Script Layout

`./dotfiles help` lists every command, split into two families:

- **`bootstrap`** — one-time setup for a fresh machine: `bootstrap desktop`/`bootstrap tty` run
  the full sequence for that profile, in order. There's nothing to re-run here afterward; the
  desktop language-runtime step in particular is fresh-install only (see
  [System Prereq's](#system-prereqs)).
- **`install`** — piecewise and idempotent: re-run `install config`, `install nvim`, etc.
  any time you change something in this repo and want just that piece re-applied, without
  repeating the one-time bootstrap steps. `install config` takes no profile argument — it
  reads `~/.dotfiles-profile`, the marker the bootstrap wrote, so it always re-applies the
  profile this machine actually has. Package and zsh setup aren't in this family —
  they only run as part of `bootstrap`, since re-running them by hand either does nothing
  or risks re-tripping install-time branching (oh-my-zsh, the default-shell switch).

Each command maps to one script under `setup/`, named to match: `setup/packages` and `setup/zsh`
are shared by both profiles (both bootstrap-only); everything under `setup/desktop/` — including
`bootstrap-languages` — only ever runs on desktop; `setup/tty/config` is the tty equivalent of
`setup/desktop/config`.

## System Prereq's
`setup/packages` apt-installs a small set of OS-level packages shared by both profiles (tmux,
fzf, ripgrep, etc.) — the same list runs on TTY.

Everything language/LSP-related is desktop-only, installed by `setup/desktop/bootstrap-languages`
as part of `bootstrap desktop`: [nvm](https://github.com/nvm-sh/nvm) (Node),
[rbenv](https://rbenv.org) (Ruby), and [uv](https://docs.astral.sh/uv) (Python), plus the pinned
Node/Ruby versions set by `NODE_VERSION`/`RUBY_VERSION` at the top of that script (made default
via `nvm alias default`/`rbenv global`). Python is the exception: only the `uv` tool itself gets
installed, not a Python version, so you'll still need to run `uv python install` yourself before
mason can use `zuban`.

That step runs once, on a fresh machine. To install or switch a language version afterward, use
the version managers directly (`nvm install 26 && nvm alias default 26`, `rbenv install 3.4.1 &&
rbenv global 3.4.1`, `uv python install`) — there's no `dotfiles` command for it. Bumping
`NODE_VERSION`/`RUBY_VERSION` in the script only changes what the *next* fresh machine gets, so
it's worth doing anyway once you've settled on a newer version.

Language servers are installed by Neovim's `mason.nvim` and it manages them automatically (see
`nvim/lua/user/plugins.lua`'s `ensure_installed` list) — but that whole block, along with
`nvim-lspconfig` itself, only loads on the desktop profile (`profile.is_tty()` gates it in
`plugins.lua`), since a TTY machine never gets the runtimes above for mason to install anything
against in the first place.

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

## Misc
- I switch Escape and Caps Lock keys. On GNOME you would run the following to do this programatically, but not currently using GNOME so not including it here: `gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"`

