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
  run exenv-version-name
  assert_success "system"
}

@test "system version is not checked for existance" {
  EXENV_VERSION=system run exenv-version-name
  assert_success "system"
}

@test "EXENV_VERSION can be overridden by hook" {
  create_version "1.8.7"
  create_version "1.9.3"
  create_hook version-name test.bash <<<"EXENV_VERSION=1.9.3"

  EXENV_VERSION=1.8.7 run exenv-version-name
  assert_success "1.9.3"
}

@test "carries original IFS within hooks" {
  create_hook version-name hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export EXENV_VERSION=system
  IFS=$' \t\n' run exenv-version-name env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "EXENV_VERSION has precedence over local" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > ".elixir-version" <<<"1.8.7"
  run exenv-version-name
  assert_success "1.8.7"

  EXENV_VERSION=1.9.3 run exenv-version-name
  assert_success "1.9.3"
}

@test "local file has precedence over global" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > "${EXENV_ROOT}/version" <<<"1.8.7"
  run exenv-version-name
  assert_success "1.8.7"

  cat > ".elixir-version" <<<"1.9.3"
  run exenv-version-name
  assert_success "1.9.3"
}

@test "missing version" {
  EXENV_VERSION=1.2 run exenv-version-name
  assert_failure "exenv: version \`1.2' is not installed (set by EXENV_VERSION environment variable)"
}

@test "version with prefix in name" {
  create_version "1.8.7"
  cat > ".elixir-version" <<<"elixir-1.8.7"
  run exenv-version-name
  assert_success
  assert_output "1.8.7"
}
