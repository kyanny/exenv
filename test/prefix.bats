#!/usr/bin/env bats

load test_helper

@test "prefix" {
  mkdir -p "${EXENV_TEST_DIR}/myproject"
  cd "${EXENV_TEST_DIR}/myproject"
  echo "1.2.3" > .elixir-version
  mkdir -p "${EXENV_ROOT}/versions/1.2.3"
  run exenv-prefix
  assert_success "${EXENV_ROOT}/versions/1.2.3"
}

@test "prefix for invalid version" {
  EXENV_VERSION="1.2.3" run exenv-prefix
  assert_failure "exenv: version \`1.2.3' not installed"
}

@test "prefix for system" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  touch "${EXENV_TEST_DIR}/bin/elixir"
  chmod +x "${EXENV_TEST_DIR}/bin/elixir"
  EXENV_VERSION="system" run exenv-prefix
  assert_success "$EXENV_TEST_DIR"
}

@test "prefix for system in /" {
  mkdir -p "${BATS_TEST_DIRNAME}/libexec"
  cat >"${BATS_TEST_DIRNAME}/libexec/exenv-which" <<OUT
#!/bin/sh
echo /bin/elixir
OUT
  chmod +x "${BATS_TEST_DIRNAME}/libexec/exenv-which"
  EXENV_VERSION="system" run exenv-prefix
  assert_success "/"
  rm -f "${BATS_TEST_DIRNAME}/libexec/exenv-which"
}

@test "prefix for invalid system" {
  PATH="$(path_without elixir)" run exenv-prefix system
  assert_failure "exenv: system version not found in PATH"
}
