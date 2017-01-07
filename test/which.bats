#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin
  if [[ $1 == */* ]]; then bin="$1"
  else bin="${EXENV_ROOT}/versions/${1}/bin"
  fi
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "outputs path to executable" {
  create_executable "1.8" "elixir"
  create_executable "2.0" "rspec"

  EXENV_VERSION=1.8 run exenv-which elixir
  assert_success "${EXENV_ROOT}/versions/1.8/bin/elixir"

  EXENV_VERSION=2.0 run exenv-which rspec
  assert_success "${EXENV_ROOT}/versions/2.0/bin/rspec"
}

@test "searches PATH for system version" {
  create_executable "${EXENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${EXENV_ROOT}/shims" "kill-all-humans"

  EXENV_VERSION=system run exenv-which kill-all-humans
  assert_success "${EXENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims prepended)" {
  create_executable "${EXENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${EXENV_ROOT}/shims" "kill-all-humans"

  PATH="${EXENV_ROOT}/shims:$PATH" EXENV_VERSION=system run exenv-which kill-all-humans
  assert_success "${EXENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims appended)" {
  create_executable "${EXENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${EXENV_ROOT}/shims" "kill-all-humans"

  PATH="$PATH:${EXENV_ROOT}/shims" EXENV_VERSION=system run exenv-which kill-all-humans
  assert_success "${EXENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims spread)" {
  create_executable "${EXENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${EXENV_ROOT}/shims" "kill-all-humans"

  PATH="${EXENV_ROOT}/shims:${EXENV_ROOT}/shims:/tmp/non-existent:$PATH:${EXENV_ROOT}/shims" \
    EXENV_VERSION=system run exenv-which kill-all-humans
  assert_success "${EXENV_TEST_DIR}/bin/kill-all-humans"
}

@test "doesn't include current directory in PATH search" {
  export PATH="$(path_without "kill-all-humans")"
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
  touch kill-all-humans
  chmod +x kill-all-humans
  EXENV_VERSION=system run exenv-which kill-all-humans
  assert_failure "exenv: kill-all-humans: command not found"
}

@test "version not installed" {
  create_executable "2.0" "rspec"
  EXENV_VERSION=1.9 run exenv-which rspec
  assert_failure "exenv: version \`1.9' is not installed (set by EXENV_VERSION environment variable)"
}

@test "no executable found" {
  create_executable "1.8" "rspec"
  EXENV_VERSION=1.8 run exenv-which rake
  assert_failure "exenv: rake: command not found"
}

@test "no executable found for system version" {
  export PATH="$(path_without "rake")"
  EXENV_VERSION=system run exenv-which rake
  assert_failure "exenv: rake: command not found"
}

@test "executable found in other versions" {
  create_executable "1.8" "elixir"
  create_executable "1.9" "rspec"
  create_executable "2.0" "rspec"

  EXENV_VERSION=1.8 run exenv-which rspec
  assert_failure
  assert_output <<OUT
exenv: rspec: command not found

The \`rspec' command exists in these Elixir versions:
  1.9
  2.0
OUT
}

@test "carries original IFS within hooks" {
  create_hook which hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' EXENV_VERSION=system run exenv-which anything
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "discovers version from exenv-version-name" {
  mkdir -p "$EXENV_ROOT"
  cat > "${EXENV_ROOT}/version" <<<"1.8"
  create_executable "1.8" "elixir"

  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"

  EXENV_VERSION= run exenv-which elixir
  assert_success "${EXENV_ROOT}/versions/1.8/bin/elixir"
}
