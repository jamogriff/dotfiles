# $HOME sweet $HOME (inspired by Jess Archer) 

This repo is a highly curated collection of config files and installation scripts that reliably setup a functioning development machine or server in less than a minute.
It includes an aesthetic font (IBM Plex Mono), zsh, a terminal (kitty), NeoVim with plugins and LSPs, and version managers for Node (nvm), Python (uv) and Ruby (rbenv). 
Additionally, Node 24 and Python 3.14 are installed and ready to go after running the `bootstrap` script.

**Note:** This was designed for use on Debian/Ubuntu/PopOS machines, so several scripts call `apt-get` to download dependencies.
It likely could be easily ported to other flavors of Linux/Unix just by replacing the `apt-get` usages with your distro's package manager (and changing the `apt-get` mock in `tests`).

## Get Started

Two profiles, scoped very differently on purpose:

- **Desktop** — a full dev environment: version managers, LSPs, every editor plugin, a GUI
  terminal.
- **TTY** — minimal, for servers: zsh and nvim as a plain editor, plus Docker.

On a fresh machine: Copy `.env.example` to `.env` and set `DOTFILES_PROFILE` to `tty` or `desktop` (default) and run `./dotfiles bootstrap`.

Assuming all goes well, you can restart your machine and it will drop you into zsh (oh my zsh!).
Launch `nvim` next. On desktop, `lazy.nvim` installs every plugin and `mason.nvim` installs the
configured language servers — see [Using lazy.nvim and mason.nvim](#using-lazynvim-and-masonnvim).
On tty you get the editor and its core plugins.

Two things bootstrap deliberately leaves to you: `sudo systemctl enable --now docker` (and a
re-login for the `docker` group), and installing a Ruby — see [System Prereq's](#system-prereqs).


### Script Layout

Everything lives in `src/`, one file per thing it does, each runnable on its own with no
arguments:

```
src/
  install-packages          # apt: xclip tmux curl unzip fzf ripgrep    (desktop)
  install-zsh               # zsh + oh-my-zsh (vendor defaults) + chsh   (both)
  install-version-managers  # nvm(+Node), rbenv, uv(+Python)            (desktop)
  install-kitty             # Kitty terminal + .desktop entries         (desktop)
  install-fonts             # IBM Plex Mono Nerd Font into ~/.fonts     (desktop)
  install-nvim              # Neovim AppImage                           (both)
  install-docker            # Docker Engine + Compose plugin            (both)
  link-config               # symlinks under config/, scripts/ and .env (both)
  lib/
    link.bash               # link_config / link_zsh_custom / link_bin  (sourced only)
    profile.bash            # resolve + validate DOTFILES_PROFILE       (sourced only)
    versions.bash           # NVIM_VERSION, FONT_VERSION, KITTY_VERSION,
                             # NODE_VERSION, PYTHON_VERSION, installer pins (sourced only)
```

`./dotfiles <script-name>` runs one of them; `./dotfiles bootstrap` runs the sequence for this
machine's profile:

| Order | desktop | tty |
|---|---|---|
| 1 | `install-packages` | — |
| 2 | `install-zsh` | `install-zsh` |
| 3 | `install-version-managers` | — |
| 4 | `install-kitty` | — |
| 5 | `install-fonts` | — |
| 6 | `install-nvim` | `install-nvim` |
| 7 | `install-docker` | `install-docker` |
| 8 | `link-config` | `link-config` |


### The `config/` directory

Everything this repo symlinks into place lives under `config/`, and where each entry lands is
decided by its shape rather than a per-file list:

| Entry | Shape | Symlinked to |
|---|---|---|
| `config/nvim/` | directory | `~/.config/nvim` |
| `config/kitty/` | directory | `~/.config/kitty` (desktop only) |
| `config/.tmux.conf` | file | `~/.tmux.conf` (desktop only) |
| `config/.gitconfig` | file | `~/.gitconfig` |
| `config/.ideavimrc` | file | `~/.ideavimrc` (desktop only) |
| `config/zsh/` | directory | *(exception — see below)* |

- **A directory** becomes `~/.config/<name>`.
- **A file** becomes `~/<name>` — an identity mapping with no exceptions, which is why every flat
  entry keeps its leading dot.

`config/zsh/` is the one real exception: oh-my-zsh sources each `*.zsh` file in `$ZSH_CUSTOM`
individually, so those get linked file by file rather than as a directory.

`install-zsh` does **not** preserve `~/.zshrc`. It runs the oh-my-zsh installer without
`KEEP_ZSHRC`, so any existing `~/.zshrc` is renamed to `~/.zshrc.pre-oh-my-zsh` and replaced
with oh-my-zsh's own default template the next time the installer actually runs (i.e., if
`~/.oh-my-zsh` doesn't already exist). Anything you want to survive that — theme, plugins,
aliases, functions, `.env` sourcing — belongs in `config/zsh/custom.zsh`, which is symlinked into
`$ZSH_CUSTOM` and auto-sourced by oh-my-zsh on every shell start, regardless of what's in
`~/.zshrc`.

Which *names* each profile gets is the single `case` block at the top of `src/link-config`.
Adding something to `config/` means adding it to at least one branch; `tests/link-config.bats`
fails if an entry is in neither.

`scripts/` (`~/.local/bin/<name>`) deliberately stays outside `config/`. Fonts aren't in the repo
at all: `src/install-fonts` downloads the pinned
[nerd-fonts](https://github.com/ryanoasis/nerd-fonts) release into `~/.fonts` during
`bootstrap` on desktop, so `config/kitty/kitty.conf` has a `BlexMono Nerd Font Mono` to match
against.

### Re-linking config

Editing a symlinked file takes effect immediately. `./dotfiles link-config` is for the cases where
a symlink doesn't exist yet and only a re-run creates it:

- **A new file was added** under `config/`.
- **A source path changed** — existing symlinks point at the old path.
- **A conditional target finally exists** — `.env` is the example: absent at bootstrap, it just
  warns.
- **Drift or accidental damage** — something overwrote a symlink with a real file.

### Machine-specific env vars: `.env`

`.env` at the repo root holds `DOTFILES_PROFILE` and machine-specific values like
`INTELEPHENSE_LICENSE`. It's git-ignored; `.env.example` is the committed template. Every line
needs `export` — nvim reads these from its environment, and a bare assignment sourced by
`config/zsh/custom.zsh` is a shell variable, not an exported one.

```
cp .env.example .env
$EDITOR .env
./dotfiles link-config
```

`src/link-config` symlinks it to `~/.env` on both profiles, and `config/zsh/custom.zsh` sources
it on every shell start.

## System Prereq's

`src/install-packages` apt-installs a small set of OS-level packages (tmux, fzf, ripgrep, etc.) on
desktop. TTY goes without them: `install-nvim` apt-installs `curl` itself if it has to, and
`live_grep` just isn't available there.

`src/install-version-managers` is desktop-only and installs
[nvm](https://github.com/nvm-sh/nvm) (Node), [rbenv](https://rbenv.org) (Ruby) and
[uv](https://docs.astral.sh/uv) (Python), plus the build dependencies `ruby-build` needs, a pinned
Node, and Python 3.14 set as the global default so `python3` just works. It does **not** build a
Ruby. Mason needs a Ruby on `$PATH` for `ruby-lsp`, so run `rbenv install <version> && rbenv global
<version>` *before* launching `nvim` for the first time. Otherwise mason's first-run
`ensure_installed` pass fails for that server and you'll need to `:MasonInstall ruby-lsp` by hand
afterwards. No PHP is installed on the host; `intelephense` runs on Node.

Afterwards, use the version managers directly (`nvm install 26 && nvm alias default 26`, `uv python
install 3.15`) — there's no `dotfiles` command for it. Bumping the pins only changes what the
*next* fresh machine gets.

`src/install-docker` runs on both profiles and installs Docker Engine and the Compose plugin from
Docker's own apt repository (rather than the `get.docker.com` convenience script, so it's pinnable
and re-runnable). Pop!_OS reports its own codename, so the repo line is built from
`UBUNTU_CODENAME` in `/etc/os-release`. Two manual steps afterwards, deliberately not automated —
whether the daemon runs at boot is a per-machine decision:

```
sudo systemctl enable --now docker
```

...then log out and back in so the `docker` group membership applies.

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
