#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${EXENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
}

@test "no version selected" {
  assert [ ! -d "${EXENV_ROOT}/versions" ]
  run exenv-version
  assert_success "system (set by ${EXENV_ROOT}/version)"
}

@test "set by EXENV_VERSION" {
  create_version "1.9.3"
  EXENV_VERSION=1.9.3 run exenv-version
  assert_success "1.9.3 (set by EXENV_VERSION environment variable)"
}

@test "set by local file" {
  create_version "1.9.3"
  cat > ".elixir-version" <<<"1.9.3"
  run exenv-version
  assert_success "1.9.3 (set by ${PWD}/.elixir-version)"
}

@test "set by global file" {
  create_version "1.9.3"
  cat > "${EXENV_ROOT}/version" <<<"1.9.3"
  run exenv-version
  assert_success "1.9.3 (set by ${EXENV_ROOT}/version)"
}
