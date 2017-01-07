#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
}

@test "reports global file even if it doesn't exist" {
  assert [ ! -e "${EXENV_ROOT}/version" ]
  run exenv-version-origin
  assert_success "${EXENV_ROOT}/version"
}

@test "detects global file" {
  mkdir -p "$EXENV_ROOT"
  touch "${EXENV_ROOT}/version"
  run exenv-version-origin
  assert_success "${EXENV_ROOT}/version"
}

@test "detects EXENV_VERSION" {
  EXENV_VERSION=1 run exenv-version-origin
  assert_success "EXENV_VERSION environment variable"
}

@test "detects local file" {
  touch .elixir-version
  run exenv-version-origin
  assert_success "${PWD}/.elixir-version"
}

@test "reports from hook" {
  create_hook version-origin test.bash <<<"EXENV_VERSION_ORIGIN=plugin"

  EXENV_VERSION=1 run exenv-version-origin
  assert_success "plugin"
}

@test "carries original IFS within hooks" {
  create_hook version-origin hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export EXENV_VERSION=system
  IFS=$' \t\n' run exenv-version-origin env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "doesn't inherit EXENV_VERSION_ORIGIN from environment" {
  EXENV_VERSION_ORIGIN=ignored run exenv-version-origin
  assert_success "${EXENV_ROOT}/version"
}
