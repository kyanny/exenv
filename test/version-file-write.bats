#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
}

@test "invocation without 2 arguments prints usage" {
  run exenv-version-file-write
  assert_failure "Usage: exenv version-file-write <file> <version>"
  run exenv-version-file-write "one" ""
  assert_failure
}

@test "setting nonexistent version fails" {
  assert [ ! -e ".elixir-version" ]
  run exenv-version-file-write ".elixir-version" "1.8.7"
  assert_failure "exenv: version \`1.8.7' not installed"
  assert [ ! -e ".elixir-version" ]
}

@test "writes value to arbitrary file" {
  mkdir -p "${EXENV_ROOT}/versions/1.8.7"
  assert [ ! -e "my-version" ]
  run exenv-version-file-write "${PWD}/my-version" "1.8.7"
  assert_success ""
  assert [ "$(cat my-version)" = "1.8.7" ]
}
