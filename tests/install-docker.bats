#!/usr/bin/env bats
# Exercises the real src/install-docker with apt-get/sudo/curl/dpkg/id/usermod
# mocked out and $ETC_DIR pointed at a scratch tree, so nothing touches apt's
# real configuration or the account's groups.

load test_helper

setup() {
  fake_home
  use_mocks

  export ETC_DIR="$BATS_TEST_TMPDIR/etc"
  mkdir -p "$ETC_DIR/apt/sources.list.d"
  os_release pop
}

# Pop!_OS is the interesting shape: ID=pop with its own VERSION_CODENAME, and a
# separate UBUNTU_CODENAME naming the release Docker actually publishes for.
os_release() {
  case "$1" in
    pop)    printf 'ID=pop\nVERSION_CODENAME=noble\nUBUNTU_CODENAME=noble\n' ;;
    ubuntu) printf 'ID=ubuntu\nVERSION_CODENAME=jammy\n' ;;
    neither) printf 'ID=weird\n' ;;
  esac > "$ETC_DIR/os-release"
}

expected_repo_line() {
  echo "deb [arch=amd64 signed-by=$ETC_DIR/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $1 stable"
}

@test "writes the keyring and the sources list for UBUNTU_CODENAME" {
  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]

  [ -f "$ETC_DIR/apt/keyrings/docker.asc" ]
  [ "$(cat "$ETC_DIR/apt/sources.list.d/docker.list")" = "$(expected_repo_line noble)" ]
}

@test "falls back to VERSION_CODENAME when UBUNTU_CODENAME is absent" {
  os_release ubuntu
  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  [ "$(cat "$ETC_DIR/apt/sources.list.d/docker.list")" = "$(expected_repo_line jammy)" ]
}

@test "fails loudly when neither codename resolves" {
  os_release neither
  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 1 ]
  [[ "$output" == *"neither UBUNTU_CODENAME nor VERSION_CODENAME"* ]]
  [ ! -e "$ETC_DIR/apt/sources.list.d/docker.list" ]
}

@test "installs the engine, CLI, containerd and both plugins" {
  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  grep -q "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" "$MOCK_LOG"
}

@test "a second run rewrites neither the keyring nor the sources list" {
  bash "$REPO_DIR/src/install-docker"
  : > "$MOCK_LOG"
  local before
  before="$(stat -c %Y "$ETC_DIR/apt/keyrings/docker.asc")"

  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already present, skipping"* ]]
  [[ "$output" == *"already points at the noble repo, skipping"* ]]
  ! grep -q "curl" "$MOCK_LOG"
  [ "$(stat -c %Y "$ETC_DIR/apt/keyrings/docker.asc")" = "$before" ]
}

@test "rewrites the sources list when it names a different codename" {
  bash "$REPO_DIR/src/install-docker"
  os_release ubuntu

  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  [ "$(cat "$ETC_DIR/apt/sources.list.d/docker.list")" = "$(expected_repo_line jammy)" ]
}

@test "adds the user to the docker group when they aren't in it" {
  MOCK_USER_GROUPS="user sudo" run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  grep -q "usermod -aG docker" "$MOCK_LOG"
}

@test "leaves group membership alone when the user is already in it" {
  MOCK_USER_GROUPS="user sudo docker" run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already in the docker group, skipping"* ]]
  ! grep -q "usermod" "$MOCK_LOG"
}

@test "never touches systemd -- enabling the service is a manual step" {
  run bash "$REPO_DIR/src/install-docker"
  [ "$status" -eq 0 ]
  ! grep -q "systemctl" "$MOCK_LOG"
  [[ "$output" == *"sudo systemctl enable --now docker"* ]]
}
