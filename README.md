# $HOME sweet $HOME

A curated set of config files and install scripts for turning a fresh machine into a place you
actually want to work. One command gets you oh-my-zsh, the kitty terminal with aesthetic font, tmux,
curated Neovim with language servers, and nvm, uv and rbenv with
Node 24 and Python 3.14 already installed. Minutes later you're writing code, not configuring.

It runs on Debian, Ubuntu and PopOS through `apt-get`, and on macOS through Homebrew, which
bootstrap installs for you. The OS is detected from `uname`, so there's nothing to tell it.

## Get started

There are two profiles, and they're scoped very differently on purpose:

- **desktop** is the full dev environment: version managers, language servers, every editor
  plugin and a GUI terminal. It's the only profile macOS supports.
- **tty** is the minimal cut for Linux servers: zsh, nvim as a plain editor, and Docker. Nothing
  that needs a display or a language runtime.

On a fresh machine, pick one and go:

```
cp .env.example .env    # set DOTFILES_PROFILE to desktop or tty
./dotfiles bootstrap
```

Log out and back in and you'll land in zsh. Launch `nvim` next: on desktop, lazy.nvim fetches
the plugins and mason installs the language servers on that first run.
Bootstrap deliberately leaves three things in your hands, because they're per-machine decisions:

- **Start Docker when you want it.** On Linux, `sudo systemctl enable --now docker`, then log out
  and back in so the `docker` group applies. On macOS, `colima start`, or
  `brew services start colima` if you'd like it running at login.
- **Install a Ruby** before launching `nvim` for the first time, otherwise mason's install of
  `ruby-lsp` fails and you'll be running `:MasonInstall ruby-lsp` by hand later:
  `rbenv install 3.4.1 && rbenv global 3.4.1`. From here on, versions are the managers'
  business (`nvm install 26`, `uv python install 3.15`); there's no `dotfiles` command for it.
- **Add your `INTELEPHENSE_LICENSE`** to `.env` if you have one. Without it, intelephense runs
  unlicensed, which is still perfectly usable.

Everything is safe to re-run. `./dotfiles bootstrap` on an already-provisioned machine is a
no-op, and `./dotfiles <script-name>` re-runs a single step when you only need the one.

### A note for Mac users

Nothing to install first beyond an account with admin rights. The Homebrew installer pulls in
the Xcode Command Line Tools along the way and asks for your password once. A few things work
differently from Linux, all by design: brew installs whatever neovim, kitty and the font are
current, so only the nvm, uv, Node and Python pins in `src/lib/versions.bash` apply; Docker is
the CLI plus [colima](https://github.com/abiosoft/colima) rather than Docker Desktop; tmux
copies with `pbcopy` instead of `xclip`; and there's no PDF viewer installed, because Preview
is right there.

## How it's laid out

```
dotfiles                    # dispatcher: `bootstrap`, or one step by name
src/install-*               # one script per step; each branches on Linux vs macOS
src/link-config             # symlinks config/, scripts/ and .env into $HOME
src/lib/                    # sourced helpers: OS detection, profile, link rules, version pins
config/                     # everything that gets symlinked
scripts/                    # ~/.local/bin extras (the `t` tmux session picker)
tests/                      # bats suite; mocks keep it off the network and package managers
```

Which steps run, and in what order, lives in the `bootstrap` function in `dotfiles`, with a
comment on why the order matters. Every step is a plain bash script that also runs on its own
with no arguments, and each one opens with a header comment spelling out the manual equivalent,
so if you'd rather do a step by hand, the recipe is right there.

### Where `config/` ends up

The rule is simple enough to keep in your head:

- **A directory** becomes `~/.config/<name>`: `nvim`, `kitty`.
- **A file** becomes `~/<name>`: `.gitconfig`, `.tmux.conf`, `.ideavimrc`. It's an identity
  mapping with no exceptions, which is why every flat entry keeps its leading dot.
- **`config/zsh/*.zsh`** is the one special case. oh-my-zsh sources individual files from
  `$ZSH_CUSTOM`, so these are linked one by one. `~/.zshrc` itself belongs to the oh-my-zsh
  installer and is disposable; anything you want to keep goes in `config/zsh/custom.zsh`.
- **`.env`** is linked to `~/.env` and sourced on every shell start. It's git-ignored, with
  `.env.example` as the committed template. Every line needs `export`, because nvim reads
  these from its environment rather than from the shell.

The list of which names each profile gets is the `case` block at the top of
`src/link-config`, and `tests/link-config.bats` will fail the moment a `config/` entry is in
neither list, so nothing gets forgotten. Since everything is a symlink, editing a file takes
effect immediately. You only need `./dotfiles link-config` again after adding a new file,
moving one, or accidentally overwriting a link with a real file.

## Cheatsheets

Once you're set up, these are the two you'll keep coming back to:

- [Neovim](neovim-cheatsheet.md): every keybinding, plus how to work with lazy.nvim and
  mason.nvim when you want to add a plugin or a language server.
- [tmux](tmux-cheatsheet.md): the keybindings and the `t` session picker that ties them
  together.

## Tests

```
bats tests
```

The scripts run for real against a throwaway `$HOME`, with `apt-get`, `brew`, `curl` and the
rest replaced by the stand-ins in `tests/mocks/`, so the suite never touches the network or a
package manager. It exercises the Linux path by default and the macOS path wherever a test sets
`DOTFILES_OS=macos`, which means you can run it on either OS and trust the result.
