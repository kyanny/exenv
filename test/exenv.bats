#!/usr/bin/env bats

load test_helper

@test "blank invocation" {
  run exenv
  assert_failure
  assert_line 0 "$(exenv---version)"
}

@test "invalid command" {
  run exenv does-not-exist
  assert_failure
  assert_output "exenv: no such command \`does-not-exist'"
}

@test "default EXENV_ROOT" {
  EXENV_ROOT="" HOME=/home/mislav run exenv root
  assert_success
  assert_output "/home/mislav/.exenv"
}

@test "inherited EXENV_ROOT" {
  EXENV_ROOT=/opt/exenv run exenv root
  assert_success
  assert_output "/opt/exenv"
}

@test "default EXENV_DIR" {
  run exenv echo EXENV_DIR
  assert_output "$(pwd)"
}

@test "inherited EXENV_DIR" {
  dir="${BATS_TMPDIR}/myproject"
  mkdir -p "$dir"
  EXENV_DIR="$dir" run exenv echo EXENV_DIR
  assert_output "$dir"
}

@test "invalid EXENV_DIR" {
  dir="${BATS_TMPDIR}/does-not-exist"
  assert [ ! -d "$dir" ]
  EXENV_DIR="$dir" run exenv echo EXENV_DIR
  assert_failure
  assert_output "exenv: cannot change working directory to \`$dir'"
}

@test "adds its own libexec to PATH" {
  run exenv echo "PATH"
  assert_success "${BATS_TEST_DIRNAME%/*}/libexec:$PATH"
}

@test "adds plugin bin dirs to PATH" {
  mkdir -p "$EXENV_ROOT"/plugins/elixir-build/bin
  mkdir -p "$EXENV_ROOT"/plugins/exenv-each/bin
  run exenv echo -F: "PATH"
  assert_success
  assert_line 0 "${BATS_TEST_DIRNAME%/*}/libexec"
  assert_line 1 "${EXENV_ROOT}/plugins/elixir-build/bin"
  assert_line 2 "${EXENV_ROOT}/plugins/exenv-each/bin"
}

@test "EXENV_HOOK_PATH preserves value from environment" {
  EXENV_HOOK_PATH=/my/hook/path:/other/hooks run exenv echo -F: "EXENV_HOOK_PATH"
  assert_success
  assert_line 0 "/my/hook/path"
  assert_line 1 "/other/hooks"
  assert_line 2 "${EXENV_ROOT}/exenv.d"
}

@test "EXENV_HOOK_PATH includes exenv built-in plugins" {
  unset EXENV_HOOK_PATH
  run exenv echo "EXENV_HOOK_PATH"
  assert_success "${EXENV_ROOT}/exenv.d:${BATS_TEST_DIRNAME%/*}/exenv.d:/usr/local/etc/exenv.d:/etc/exenv.d:/usr/lib/exenv/hooks"
}
