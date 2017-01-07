#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${EXENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
}

stub_system_elixir() {
  local stub="${EXENV_TEST_DIR}/bin/elixir"
  mkdir -p "$(dirname "$stub")"
  touch "$stub" && chmod +x "$stub"
}

@test "no versions installed" {
  stub_system_elixir
  assert [ ! -d "${EXENV_ROOT}/versions" ]
  run exenv-versions
  assert_success "* system (set by ${EXENV_ROOT}/version)"
}

@test "not even system elixir available" {
  PATH="$(path_without elixir)" run exenv-versions
  assert_failure
  assert_output "Warning: no Elixir detected on the system"
}

@test "bare output no versions installed" {
  assert [ ! -d "${EXENV_ROOT}/versions" ]
  run exenv-versions --bare
  assert_success ""
}

@test "single version installed" {
  stub_system_elixir
  create_version "1.9"
  run exenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${EXENV_ROOT}/version)
  1.9
OUT
}

@test "single version bare" {
  create_version "1.9"
  run exenv-versions --bare
  assert_success "1.9"
}

@test "multiple versions" {
  stub_system_elixir
  create_version "1.8.7"
  create_version "1.9.3"
  create_version "2.0.0"
  run exenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${EXENV_ROOT}/version)
  1.8.7
  1.9.3
  2.0.0
OUT
}

@test "indicates current version" {
  stub_system_elixir
  create_version "1.9.3"
  create_version "2.0.0"
  EXENV_VERSION=1.9.3 run exenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by EXENV_VERSION environment variable)
  2.0.0
OUT
}

@test "bare doesn't indicate current version" {
  create_version "1.9.3"
  create_version "2.0.0"
  EXENV_VERSION=1.9.3 run exenv-versions --bare
  assert_success
  assert_output <<OUT
1.9.3
2.0.0
OUT
}

@test "globally selected version" {
  stub_system_elixir
  create_version "1.9.3"
  create_version "2.0.0"
  cat > "${EXENV_ROOT}/version" <<<"1.9.3"
  run exenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${EXENV_ROOT}/version)
  2.0.0
OUT
}

@test "per-project version" {
  stub_system_elixir
  create_version "1.9.3"
  create_version "2.0.0"
  cat > ".elixir-version" <<<"1.9.3"
  run exenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${EXENV_TEST_DIR}/.elixir-version)
  2.0.0
OUT
}

@test "ignores non-directories under versions" {
  create_version "1.9"
  touch "${EXENV_ROOT}/versions/hello"

  run exenv-versions --bare
  assert_success "1.9"
}

@test "lists symlinks under versions" {
  create_version "1.8.7"
  ln -s "1.8.7" "${EXENV_ROOT}/versions/1.8"

  run exenv-versions --bare
  assert_success
  assert_output <<OUT
1.8
1.8.7
OUT
}

@test "doesn't list symlink aliases when --skip-aliases" {
  create_version "1.8.7"
  ln -s "1.8.7" "${EXENV_ROOT}/versions/1.8"
  mkdir moo
  ln -s "${PWD}/moo" "${EXENV_ROOT}/versions/1.9"

  run exenv-versions --bare --skip-aliases
  assert_success

  assert_output <<OUT
1.8.7
1.9
OUT
}
