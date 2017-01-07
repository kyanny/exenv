#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "${EXENV_TEST_DIR}/myproject"
  cd "${EXENV_TEST_DIR}/myproject"
}

@test "no version" {
  assert [ ! -e "${PWD}/.elixir-version" ]
  run exenv-local
  assert_failure "exenv: no local version configured for this directory"
}

@test "local version" {
  echo "1.2.3" > .elixir-version
  run exenv-local
  assert_success "1.2.3"
}

@test "discovers version file in parent directory" {
  echo "1.2.3" > .elixir-version
  mkdir -p "subdir" && cd "subdir"
  run exenv-local
  assert_success "1.2.3"
}

@test "ignores EXENV_DIR" {
  echo "1.2.3" > .elixir-version
  mkdir -p "$HOME"
  echo "2.0-home" > "${HOME}/.elixir-version"
  EXENV_DIR="$HOME" run exenv-local
  assert_success "1.2.3"
}

@test "sets local version" {
  mkdir -p "${EXENV_ROOT}/versions/1.2.3"
  run exenv-local 1.2.3
  assert_success ""
  assert [ "$(cat .elixir-version)" = "1.2.3" ]
}

@test "changes local version" {
  echo "1.0-pre" > .elixir-version
  mkdir -p "${EXENV_ROOT}/versions/1.2.3"
  run exenv-local
  assert_success "1.0-pre"
  run exenv-local 1.2.3
  assert_success ""
  assert [ "$(cat .elixir-version)" = "1.2.3" ]
}

@test "unsets local version" {
  touch .elixir-version
  run exenv-local --unset
  assert_success ""
  assert [ ! -e .elixir-version ]
}
