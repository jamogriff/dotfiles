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

`./dotfiles help` lists every command, split into three families:

- **`bootstrap`** — one-time setup for a fresh machine: `bootstrap desktop`/`bootstrap tty` run
  the full sequence for that profile, in order. There's nothing to re-run here afterward; the
  desktop language-runtime step in particular is fresh-install only (see
  [System Prereq's](#system-prereqs)).
- **`install`** — piecewise and idempotent: re-run `install nvim` or `install terminal` any
  time you want just that piece of third-party software re-installed, without repeating the
  one-time bootstrap steps. Package and zsh setup aren't in this family — they only run as
  part of `bootstrap`, since re-running them by hand either does nothing or risks re-tripping
  install-time branching (oh-my-zsh, the default-shell switch).
- **`sync`** — `sync config` reconciles this machine's symlinks against what the repo currently
  says. Its own family rather than an `install` subcommand because it installs nothing. It takes
  no profile argument — it reads `~/.dotfiles-profile`, the marker the bootstrap wrote, so it
  always re-applies the profile this machine actually has. See
  [Syncing config](#syncing-config) for when you actually need it.

Each command maps to one script under `setup/`, named to match: `setup/packages` and `setup/zsh`
are shared by both profiles (both bootstrap-only); everything under `setup/desktop/` — including
`bootstrap-languages` — only ever runs on desktop; `setup/tty/config` is the tty equivalent of
`setup/desktop/config`. `setup/lib/config.bash` isn't a command — it's the shared symlinking
both `config` scripts source.

### The `config/` directory

Everything this repo symlinks into place lives under `config/`, and where each entry lands is
decided by its shape rather than a per-file list:

| Entry | Shape | Symlinked to |
|---|---|---|
| `config/nvim/` | directory | `~/.config/nvim` |
| `config/kitty/` | directory | `~/.config/kitty` (desktop only) |
| `config/.tmux.conf` | file | `~/.tmux.conf` |
| `config/.gitconfig` | file | `~/.gitconfig` |
| `config/.ideavimrc` | file | `~/.ideavimrc` (desktop only) |
| `config/zsh/` | directory | *(exception — see below)* |

- **A directory** becomes `~/.config/<name>`.
- **A file** becomes `~/<name>` — a plain identity mapping with no exceptions, which is why
  every flat entry keeps its leading dot (`tmux.conf` gained one when it moved out of `tmux/`).
  A directory holding only one file lives flat in `config/` instead of getting its own
  subdirectory.

`config/zsh/` is the one real exception: oh-my-zsh sources each `*.zsh` file in `$ZSH_CUSTOM`
individually, so those get linked file by file rather than as a directory, and only if
`~/.oh-my-zsh` already exists.

Which *names* each profile gets is still an explicit list at the top of `setup/desktop/config`
and `setup/tty/config` — `kitty` and `.ideavimrc` are desktop-only. The convention above only
decides how to link one name once a profile has picked it. Adding something to `config/` means
adding it to at least one of those two lists; `tests/{desktop,tty}-config.bats` fail if an entry
is in neither.

`fonts/` (unzipped, not symlinked) and `scripts/` (`~/.local/bin/<name>`, nothing to do with
`~/.config/`) deliberately stay outside `config/`.

### Syncing config

Editing a symlinked file takes effect immediately — no re-run needed. `sync config` is for the
cases where a symlink doesn't exist yet and only a re-run creates it:

- **A new file was added** — a new `config/zsh/*.zsh` isn't sourced by oh-my-zsh until the
  per-file symlink loop runs again.
- **A source path changed** — existing symlinks point at the old path until it re-creates them.
- **A conditional target finally exists** — `.env` is the example: absent at bootstrap, it just
  warns; add it later and only a re-run creates the live symlink.
- **Drift or accidental damage** — something deleted `~/.config/nvim` or overwrote
  `~/.tmux.conf` with a real file. This is the one-step way back.

### Machine-specific env vars: `.env`

`.env` at the repo root holds machine-specific environment variables (currently just
`INTELEPHENSE_LICENSE`). It's git-ignored; `.env.example` next to it is the committed template.
Copy it, fill it in, and run `dotfiles sync config`:

```
cp .env.example .env
$EDITOR .env
./dotfiles sync config
```

`setup/desktop/config` symlinks it to `~/.env`, and `setup/zsh` is what adds the block sourcing
that from `~/.zshrc`. It's desktop-only, in line with the licence key being for a mason-installed
language server.

### Migrating from the pre-`config/` layout

A machine bootstrapped before `config/` existed has symlinks pointing at the old repo paths and
a `~/.zshrc` block sourcing the old secrets file. To bring it up to date:

1. `./dotfiles sync config` — re-creates every symlink at its new source path. This is the bulk
   of it, and nothing else will fix those links.
2. `cp .env.example .env` and move whatever was in your old `.secrets` into it, then re-run
   `./dotfiles sync config` to pick it up.
3. Two leftovers to clean up by hand, since nothing removes them for you:
   - `rm ~/.local/.secrets` — a dangling symlink now that `.secrets` is `.env`.
   - Delete the old `if [ -f $HOME/.local/.secrets ]` block from `~/.zshrc`. Without this it
     prints a spurious warning on every new shell.

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
`config/nvim/lua/user/plugins.lua`'s `ensure_installed` list) — but that whole block, along with
`nvim-lspconfig` itself, only loads on the desktop profile (`profile.is_tty()` gates it in
`plugins.lua`), since a TTY machine never gets the runtimes above for mason to install anything
against in the first place.

## Using lazy.nvim and mason.nvim

Plugins are managed by [lazy.nvim](https://lazy.folke.io), configured in
`config/nvim/lua/user/plugins.lua` and bootstrapped by `config/nvim/lua/user/lazy.lua`. Language servers are
managed by [mason.nvim](https://mason-registry.dev), configured via the `ensure_installed` list
on the `mason-lspconfig.nvim` entry in that same file.

### lazy.nvim

- `:Lazy` — open the plugin manager UI (install/update/clean status for everything).
- `:Lazy update` — install the latest version of every plugin matching its pin. Every plugin
  defaults to `version = "*"` (latest stable semver tag, when a plugin publishes one;
  otherwise its tracked branch's latest commit) via `defaults.version` in `lazy.lua`.
- `:Lazy sync` — install + clean + update in one pass; run this after adding/removing an entry
  in `plugins.lua`.
- `:Lazy restore` — reset every plugin to the exact commit recorded in `config/nvim/lazy-lock.json`
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
- add the same name to the `vim.lsp.enable({...})` call in `config/nvim/lua/user/plugins/lspconfig.lua`, or
- if it needs custom settings (like `intelephense`'s license key), call
  `vim.lsp.config('name', { ... })` first, then `vim.lsp.enable('name')`.

Mason installs into its own directory (`~/.local/share/nvim/mason`), independent of whatever
Node/Python/Ruby version your own version manager currently has active — it just needs *some*
working runtime for each language on `$PATH` at install time (see
[System Prereq's](#system-prereqs)).

## PHP Stuff

If you're intending on using PHP, `intelephense` is installed automatically by mason — you just
need to set `INTELEPHENSE_LICENSE` in the repo's `.env` file — see
[Machine-specific env vars](#machine-specific-env-vars-env).

## TODO
- Investigate a Ruby-version-manager-agnostic way to smoke-test that `ruby-lsp`'s gem install
  actually succeeds on a fresh machine (it depends on a system Ruby/gem being present).
- No SQL LSP is enabled: mason's `sqlls` (`sql-language-server@1.7.1`, the latest release)
  crashes on startup with `ERR_PACKAGE_PATH_NOT_EXPORTED`, a bug in its own
  `vscode-languageserver-protocol` dependency. Revisit once upstream publishes a fix, or try
  the Go-based `sqls` instead (needs a Go toolchain, which this repo doesn't set up).

## Misc
- I switch Escape and Caps Lock keys. On GNOME you would run the following to do this programatically, but not currently using GNOME so not including it here: `gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"`

