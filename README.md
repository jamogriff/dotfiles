# dotfiles
$HOME sweet $HOME (inspired by Jess Archer)

## Get Started

Two profiles (**Linux only!**), scoped very differently on purpose:

- **Desktop** — a full dev environment: language runtimes, LSPs, every editor plugin, a GUI
  terminal.
- **TTY** — minimal, for servers: zsh and nvim as a plain editor, nothing else.

On a fresh machine, run one bootstrap command:

### Desktop Computer

1. `./dotfiles bootstrap desktop`
2. Launch `nvim`. On first run `lazy.nvim` installs every plugin and `mason.nvim` installs the
   configured language servers. See [Using lazy.nvim and mason.nvim](#using-lazynvim-and-masonnvim).

### TTY Computer

1. `./dotfiles bootstrap tty`
2. Launch `nvim` — just the editor and its core plugins; mason/lspconfig aren't loaded on this
   profile at all.

**Notes:**
- You'll likely need to set `export TERM=xterm-256color` in your `~/.zshrc` file.

### Script Layout

`./dotfiles help` lists every command, split into three families:

- **`bootstrap`** — one-time setup for a fresh machine; nothing here is meant to be re-run.
- **`install`** — piecewise and idempotent: `install nvim`, `install terminal`. Package and zsh
  setup aren't in this family — re-running them by hand either does nothing or re-trips
  install-time branching (oh-my-zsh, the default-shell switch).
- **`sync`** — `sync config` reconciles this machine's symlinks against the repo. It takes no
  profile argument: it reads `~/.dotfiles-profile`, the marker the bootstrap wrote. See
  [Syncing config](#syncing-config).

Each command maps to one script under `setup/`, named to match. `setup/packages` and `setup/zsh`
are shared; everything under `setup/desktop/` only ever runs on desktop. `setup/lib/config.bash`
isn't a command — it's the shared symlinking both `config` scripts source.

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
- **A file** becomes `~/<name>` — an identity mapping with no exceptions, which is why every flat
  entry keeps its leading dot.

`config/zsh/` is the one real exception: oh-my-zsh sources each `*.zsh` file in `$ZSH_CUSTOM`
individually, so those get linked file by file rather than as a directory.

Which *names* each profile gets is an explicit list at the top of `setup/desktop/config` and
`setup/tty/config`. Adding something to `config/` means adding it to at least one of those lists;
`tests/{desktop,tty}-config.bats` fail if an entry is in neither.

`fonts/` (unzipped, not symlinked) and `scripts/` (`~/.local/bin/<name>`) deliberately stay
outside `config/`.

### Syncing config

Editing a symlinked file takes effect immediately. `sync config` is for the cases where a symlink
doesn't exist yet and only a re-run creates it:

- **A new file was added** under `config/`.
- **A source path changed** — existing symlinks point at the old path.
- **A conditional target finally exists** — `.env` is the example: absent at bootstrap, it just
  warns.
- **Drift or accidental damage** — something overwrote a symlink with a real file.

### Machine-specific env vars: `.env`

`.env` at the repo root holds machine-specific environment variables (currently just
`INTELEPHENSE_LICENSE`). It's git-ignored; `.env.example` is the committed template. Copy it, fill
it in, and sync:

```
cp .env.example .env
$EDITOR .env
./dotfiles sync config
```

`setup/desktop/config` symlinks it to `~/.env`, and `setup/zsh` adds the block sourcing it from
`~/.zshrc`. Desktop-only, in line with the licence key being for a mason-installed server.

### Migrating from the pre-`config/` layout

A machine bootstrapped before `config/` existed has symlinks pointing at the old repo paths and a
`~/.zshrc` block sourcing the old secrets file:

1. `./dotfiles sync config` — re-creates every symlink at its new source path.
2. `cp .env.example .env`, move whatever was in your old `.secrets` into it, then sync again.
3. Two leftovers nothing removes for you:
   - `rm ~/.local/.secrets` — now a dangling symlink.
   - Delete the old `if [ -f $HOME/.local/.secrets ]` block from `~/.zshrc`, or it warns on every
     new shell.

## System Prereq's

`setup/packages` apt-installs a small set of OS-level packages shared by both profiles (tmux, fzf,
ripgrep, etc.).

Everything language/LSP-related is desktop-only, installed by `setup/desktop/bootstrap-languages`
as part of `bootstrap desktop`: [nvm](https://github.com/nvm-sh/nvm) (Node),
[rbenv](https://rbenv.org) (Ruby), and [uv](https://docs.astral.sh/uv) (Python), plus the pinned
Node/Ruby versions at the top of that script. Python is the exception: only the `uv` tool is
installed, not a Python version, so run `uv python install` yourself before mason can use `zuban`.

That step runs once. Afterwards, use the version managers directly (`nvm install 26 && nvm alias
default 26`, `rbenv install 3.4.1 && rbenv global 3.4.1`) — there's no `dotfiles` command for it.
Bumping the pins only changes what the *next* fresh machine gets.

Language servers are installed by `mason.nvim` (see `ensure_installed` in
`config/nvim/lua/user/plugins.lua`), but that block and `nvim-lspconfig` only load on desktop —
`profile.is_tty()` gates them.

## Using lazy.nvim and mason.nvim

Plugins are managed by [lazy.nvim](https://lazy.folke.io), configured in
`config/nvim/lua/user/plugins.lua` and bootstrapped by `lazy.lua`. Language servers are managed by
[mason.nvim](https://mason-registry.dev) via the `ensure_installed` list on the
`mason-lspconfig.nvim` entry in that same file.

### lazy.nvim

- `:Lazy` — open the plugin manager UI.
- `:Lazy update` — update every plugin to the latest matching its pin. Everything defaults to
  `version = "*"` (latest stable semver tag) via `defaults.version` in `lazy.lua`.
- `:Lazy sync` — install + clean + update; run this after editing `plugins.lua`.
- `:Lazy restore` — reset every plugin to the commit in `config/nvim/lazy-lock.json`.
- `:Lazy check` — check for updates without installing.
- `:checkhealth lazy` — sanity-check the install; also flags leftovers from a previous plugin
  manager.

To add a plugin: add an entry in `plugins.lua` (desktop-only ones go in the
`if not profile.is_tty() then ... end` block) and run `:Lazy sync`.

### mason.nvim

- `:Mason` — browse/install/uninstall servers by hand.
- `:MasonInstall <name>` / `:MasonUninstall <name>` — ad hoc, without touching `ensure_installed`.
- `:MasonUpdate` — refresh the package registry index.
- `:MasonLog` — logs for a server that's failing.

To add a language server permanently, add its **lspconfig server name** — not the mason package
name, they sometimes differ (mason's `html-lsp` is lspconfig's `html`; see
https://mason-registry.dev/registry/list) — to `ensure_installed`, then either:
- add the same name to `vim.lsp.enable({...})` in `config/nvim/lua/user/plugins/lspconfig.lua`, or
- if it needs custom settings (like `intelephense`'s license key), call `vim.lsp.config('name',
  { ... })` first, then `vim.lsp.enable('name')`.

Mason installs into `~/.local/share/nvim/mason`, independent of whichever version your own version
manager has active — it just needs *some* working runtime per language on `$PATH` at install time.

## PHP Stuff

`intelephense` is installed automatically by mason — you just need to set `INTELEPHENSE_LICENSE`
in the repo's `.env` file, see [Machine-specific env vars](#machine-specific-env-vars-env).

## TODO
- Investigate a Ruby-version-manager-agnostic way to smoke-test that `ruby-lsp`'s gem install
  actually succeeds on a fresh machine (it depends on a system Ruby/gem being present).
- No SQL LSP is enabled: mason's `sqlls` (`sql-language-server@1.7.1`, the latest release) crashes
  on startup with `ERR_PACKAGE_PATH_NOT_EXPORTED`, a bug in its own
  `vscode-languageserver-protocol` dependency. Revisit once upstream publishes a fix, or try the
  Go-based `sqls` instead (needs a Go toolchain, which this repo doesn't set up).

## Misc
- I switch Escape and Caps Lock keys. On GNOME you would run the following to do this programatically, but not currently using GNOME so not including it here: `gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"`
