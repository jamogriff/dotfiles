#!/usr/bin/env bats
# Exercises the REAL setup/zsh, with apt-get/sudo/curl/getent/chsh
# mocked out (see tests/mocks/). Deliberately NOT covered: whether the script
# actually switches your login shell. That branch reads real account state
# (passwd, /etc/shells) that isn't safe to fake convincingly in a sandbox --
# see the getent mock's comment for how it's kept from ever firing here.
# Everything else -- oh-my-zsh install idempotency, .zshrc content and its
# own idempotency -- runs against the real script logic.

load test_helper

setup() {
  fake_home
  use_mocks
}

@test "installs the zsh package when not already on PATH" {
  PATH="$(path_without_zsh)" run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -q "apt-get install -y zsh" "$MOCK_LOG"
}

@test "skips installing the zsh package when already on PATH" {
  # A fake zsh binary so `command -v zsh` succeeds without one being installed.
  mkdir -p "$BATS_TEST_TMPDIR/fakezsh"
  touch "$BATS_TEST_TMPDIR/fakezsh/zsh"
  chmod +x "$BATS_TEST_TMPDIR/fakezsh/zsh"
  PATH="$BATS_TEST_TMPDIR/fakezsh:$PATH" run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  ! grep -q "apt-get install" "$MOCK_LOG"
}

@test "runs the oh-my-zsh installer when ~/.oh-my-zsh is absent" {
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -q "ohmyzsh" "$MOCK_LOG"
}

@test "skips the oh-my-zsh installer when ~/.oh-my-zsh already exists" {
  mkdir -p "$HOME/.oh-my-zsh"
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed at ~/.oh-my-zsh, skipping."* ]]
  ! grep -q "ohmyzsh" "$MOCK_LOG"
}

@test "appends the oh-my-zsh bootstrap block to a fresh .zshrc" {
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -qF 'source $ZSH/oh-my-zsh.sh' "$HOME/.zshrc"
}

@test "does not duplicate the bootstrap block on a second run" {
  bash "$REPO_DIR/setup/zsh"
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  # grep -c counts matching lines; there should be exactly one, not two.
  [ "$(grep -cF 'oh-my-zsh.sh' "$HOME/.zshrc")" -eq 1 ]
}

@test "appends the .env sourcing block to a fresh .zshrc" {
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -qxF 'if [ -f $HOME/.env ]; then' "$HOME/.zshrc"
  grep -qxF '    source $HOME/.env' "$HOME/.zshrc"
}

@test "does not duplicate the .env sourcing block on a second run" {
  bash "$REPO_DIR/setup/zsh"
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  # The block contains two lines that both mention $HOME/.env (the `if` guard
  # and the `source` line), so a *correct* single append already counts 2 --
  # checking one specific line is what actually proves it wasn't appended twice.
  [ "$(grep -cxF '    source $HOME/.env' "$HOME/.zshrc")" -eq 1 ]
}

@test "appends the .env block to a .zshrc still carrying the old .secrets one" {
  # The pre-config/ spelling. setup/zsh only runs as part of `bootstrap`, so an
  # already-bootstrapped machine won't hit this -- but if it is re-run, the new
  # block must go in rather than the old one being mistaken for it. The dead
  # .secrets block is left alone; removing it is a documented manual step.
  cat > "$HOME/.zshrc" <<'EOF'
if [ -f $HOME/.local/.secrets ]; then
    source $HOME/.local/.secrets
fi
EOF
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -qxF '    source $HOME/.env' "$HOME/.zshrc"
}

@test "adds docker plugins to a bare plugins=(git) line left by another source" {
  # Simulate a .zshrc that already has our bootstrap block (so that part is
  # skipped) but still carries oh-my-zsh's own untouched default plugins line
  # -- the specific case the script's fallback comment describes.
  cat > "$HOME/.zshrc" <<'EOF'
plugins=(git)
source $ZSH/oh-my-zsh.sh
if [ -f $HOME/.env ]; then
    source $HOME/.env
fi
EOF
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  grep -qx 'plugins=(git docker-compose docker)' "$HOME/.zshrc"
}

@test "leaves a customized plugins= line alone" {
  cat > "$HOME/.zshrc" <<'EOF'
plugins=(git rust)
source $ZSH/oh-my-zsh.sh
if [ -f $HOME/.env ]; then
    source $HOME/.env
fi
EOF
  run bash "$REPO_DIR/setup/zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"leaving it as-is"* ]]
  grep -qx 'plugins=(git rust)' "$HOME/.zshrc"
}
