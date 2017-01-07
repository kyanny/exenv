#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
}

create_file() {
  mkdir -p "$(dirname "$1")"
  touch "$1"
}

@test "detects global 'version' file" {
  create_file "${EXENV_ROOT}/version"
  run exenv-version-file
  assert_success "${EXENV_ROOT}/version"
}

@test "prints global file if no version files exist" {
  assert [ ! -e "${EXENV_ROOT}/version" ]
  assert [ ! -e ".elixir-version" ]
  run exenv-version-file
  assert_success "${EXENV_ROOT}/version"
}

@test "in current directory" {
  create_file ".elixir-version"
  run exenv-version-file
  assert_success "${EXENV_TEST_DIR}/.elixir-version"
}

@test "in parent directory" {
  create_file ".elixir-version"
  mkdir -p project
  cd project
  run exenv-version-file
  assert_success "${EXENV_TEST_DIR}/.elixir-version"
}

@test "topmost file has precedence" {
  create_file ".elixir-version"
  create_file "project/.elixir-version"
  cd project
  run exenv-version-file
  assert_success "${EXENV_TEST_DIR}/project/.elixir-version"
}

@test "EXENV_DIR has precedence over PWD" {
  create_file "widget/.elixir-version"
  create_file "project/.elixir-version"
  cd project
  EXENV_DIR="${EXENV_TEST_DIR}/widget" run exenv-version-file
  assert_success "${EXENV_TEST_DIR}/widget/.elixir-version"
}

@test "PWD is searched if EXENV_DIR yields no results" {
  mkdir -p "widget/blank"
  create_file "project/.elixir-version"
  cd project
  EXENV_DIR="${EXENV_TEST_DIR}/widget/blank" run exenv-version-file
  assert_success "${EXENV_TEST_DIR}/project/.elixir-version"
}

@test "finds version file in target directory" {
  create_file "project/.elixir-version"
  run exenv-version-file "${PWD}/project"
  assert_success "${EXENV_TEST_DIR}/project/.elixir-version"
}

@test "fails when no version file in target directory" {
  run exenv-version-file "$PWD"
  assert_failure ""
}
