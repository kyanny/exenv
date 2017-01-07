#!/usr/bin/env bats

load test_helper

@test "no shell version" {
  mkdir -p "${EXENV_TEST_DIR}/myproject"
  cd "${EXENV_TEST_DIR}/myproject"
  echo "1.2.3" > .elixir-version
  EXENV_VERSION="" run exenv-sh-shell
  assert_failure "exenv: no shell-specific version configured"
}

@test "shell version" {
  EXENV_SHELL=bash EXENV_VERSION="1.2.3" run exenv-sh-shell
  assert_success 'echo "$EXENV_VERSION"'
}

@test "shell version (fish)" {
  EXENV_SHELL=fish EXENV_VERSION="1.2.3" run exenv-sh-shell
  assert_success 'echo "$EXENV_VERSION"'
}

@test "shell revert" {
  EXENV_SHELL=bash run exenv-sh-shell -
  assert_success
  assert_line 0 'if [ -n "${EXENV_VERSION_OLD+x}" ]; then'
}

@test "shell revert (fish)" {
  EXENV_SHELL=fish run exenv-sh-shell -
  assert_success
  assert_line 0 'if set -q EXENV_VERSION_OLD'
}

@test "shell unset" {
  EXENV_SHELL=bash run exenv-sh-shell --unset
  assert_success
  assert_output <<OUT
EXENV_VERSION_OLD="\$EXENV_VERSION"
unset EXENV_VERSION
OUT
}

@test "shell unset (fish)" {
  EXENV_SHELL=fish run exenv-sh-shell --unset
  assert_success
  assert_output <<OUT
set -gu EXENV_VERSION_OLD "\$EXENV_VERSION"
set -e EXENV_VERSION
OUT
}

@test "shell change invalid version" {
  run exenv-sh-shell 1.2.3
  assert_failure
  assert_output <<SH
exenv: version \`1.2.3' not installed
false
SH
}

@test "shell change version" {
  mkdir -p "${EXENV_ROOT}/versions/1.2.3"
  EXENV_SHELL=bash run exenv-sh-shell 1.2.3
  assert_success
  assert_output <<OUT
EXENV_VERSION_OLD="\$EXENV_VERSION"
export EXENV_VERSION="1.2.3"
OUT
}

@test "shell change version (fish)" {
  mkdir -p "${EXENV_ROOT}/versions/1.2.3"
  EXENV_SHELL=fish run exenv-sh-shell 1.2.3
  assert_success
  assert_output <<OUT
set -gu EXENV_VERSION_OLD "\$EXENV_VERSION"
set -gx EXENV_VERSION "1.2.3"
OUT
}
