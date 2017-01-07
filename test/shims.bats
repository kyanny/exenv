#!/usr/bin/env bats

load test_helper

@test "no shims" {
  run exenv-shims
  assert_success
  assert [ -z "$output" ]
}

@test "shims" {
  mkdir -p "${EXENV_ROOT}/shims"
  touch "${EXENV_ROOT}/shims/elixir"
  touch "${EXENV_ROOT}/shims/irb"
  run exenv-shims
  assert_success
  assert_line "${EXENV_ROOT}/shims/elixir"
  assert_line "${EXENV_ROOT}/shims/irb"
}

@test "shims --short" {
  mkdir -p "${EXENV_ROOT}/shims"
  touch "${EXENV_ROOT}/shims/elixir"
  touch "${EXENV_ROOT}/shims/irb"
  run exenv-shims --short
  assert_success
  assert_line "irb"
  assert_line "elixir"
}
