#!/usr/bin/env bats

load test_helper

@test "prints usage help given no argument" {
  run exenv-hooks
  assert_failure "Usage: exenv hooks <command>"
}

@test "prints list of hooks" {
  path1="${EXENV_TEST_DIR}/exenv.d"
  path2="${EXENV_TEST_DIR}/etc/exenv_hooks"
  EXENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  create_hook exec "ahoy.bash"
  create_hook exec "invalid.sh"
  create_hook which "boom.bash"
  EXENV_HOOK_PATH="$path2"
  create_hook exec "bueno.bash"

  EXENV_HOOK_PATH="$path1:$path2" run exenv-hooks exec
  assert_success
  assert_output <<OUT
${EXENV_TEST_DIR}/exenv.d/exec/ahoy.bash
${EXENV_TEST_DIR}/exenv.d/exec/hello.bash
${EXENV_TEST_DIR}/etc/exenv_hooks/exec/bueno.bash
OUT
}

@test "supports hook paths with spaces" {
  path1="${EXENV_TEST_DIR}/my hooks/exenv.d"
  path2="${EXENV_TEST_DIR}/etc/exenv hooks"
  EXENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  EXENV_HOOK_PATH="$path2"
  create_hook exec "ahoy.bash"

  EXENV_HOOK_PATH="$path1:$path2" run exenv-hooks exec
  assert_success
  assert_output <<OUT
${EXENV_TEST_DIR}/my hooks/exenv.d/exec/hello.bash
${EXENV_TEST_DIR}/etc/exenv hooks/exec/ahoy.bash
OUT
}

@test "resolves relative paths" {
  EXENV_HOOK_PATH="${EXENV_TEST_DIR}/exenv.d"
  create_hook exec "hello.bash"
  mkdir -p "$HOME"

  EXENV_HOOK_PATH="${HOME}/../exenv.d" run exenv-hooks exec
  assert_success "${EXENV_TEST_DIR}/exenv.d/exec/hello.bash"
}

@test "resolves symlinks" {
  path="${EXENV_TEST_DIR}/exenv.d"
  mkdir -p "${path}/exec"
  mkdir -p "$HOME"
  touch "${HOME}/hola.bash"
  ln -s "../../home/hola.bash" "${path}/exec/hello.bash"
  touch "${path}/exec/bright.sh"
  ln -s "bright.sh" "${path}/exec/world.bash"

  EXENV_HOOK_PATH="$path" run exenv-hooks exec
  assert_success
  assert_output <<OUT
${HOME}/hola.bash
${EXENV_TEST_DIR}/exenv.d/exec/bright.sh
OUT
}
