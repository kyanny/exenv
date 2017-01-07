#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${EXENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "empty rehash" {
  assert [ ! -d "${EXENV_ROOT}/shims" ]
  run exenv-rehash
  assert_success ""
  assert [ -d "${EXENV_ROOT}/shims" ]
  rmdir "${EXENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${EXENV_ROOT}/shims"
  chmod -w "${EXENV_ROOT}/shims"
  run exenv-rehash
  assert_failure "exenv: cannot rehash: ${EXENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  mkdir -p "${EXENV_ROOT}/shims"
  touch "${EXENV_ROOT}/shims/.exenv-shim"
  run exenv-rehash
  assert_failure "exenv: cannot rehash: ${EXENV_ROOT}/shims/.exenv-shim exists"
}

@test "creates shims" {
  create_executable "1.8" "elixir"
  create_executable "1.8" "rake"
  create_executable "2.0" "elixir"
  create_executable "2.0" "rspec"

  assert [ ! -e "${EXENV_ROOT}/shims/elixir" ]
  assert [ ! -e "${EXENV_ROOT}/shims/rake" ]
  assert [ ! -e "${EXENV_ROOT}/shims/rspec" ]

  run exenv-rehash
  assert_success ""

  run ls "${EXENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
rake
rspec
elixir
OUT
}

@test "removes outdated shims" {
  mkdir -p "${EXENV_ROOT}/shims"
  touch "${EXENV_ROOT}/shims/oldshim1"
  chmod +x "${EXENV_ROOT}/shims/oldshim1"

  create_executable "2.0" "rake"
  create_executable "2.0" "elixir"

  run exenv-rehash
  assert_success ""

  assert [ ! -e "${EXENV_ROOT}/shims/oldshim1" ]
}

@test "do exact matches when removing stale shims" {
  create_executable "2.0" "unicorn_rails"
  create_executable "2.0" "rspec-core"

  exenv-rehash

  cp "$EXENV_ROOT"/shims/{rspec-core,rspec}
  cp "$EXENV_ROOT"/shims/{rspec-core,rails}
  cp "$EXENV_ROOT"/shims/{rspec-core,uni}
  chmod +x "$EXENV_ROOT"/shims/{rspec,rails,uni}

  run exenv-rehash
  assert_success ""

  assert [ ! -e "${EXENV_ROOT}/shims/rails" ]
  assert [ ! -e "${EXENV_ROOT}/shims/rake" ]
  assert [ ! -e "${EXENV_ROOT}/shims/uni" ]
}

@test "binary install locations containing spaces" {
  create_executable "dirname1 p247" "elixir"
  create_executable "dirname2 preview1" "rspec"

  assert [ ! -e "${EXENV_ROOT}/shims/elixir" ]
  assert [ ! -e "${EXENV_ROOT}/shims/rspec" ]

  run exenv-rehash
  assert_success ""

  run ls "${EXENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
rspec
elixir
OUT
}

@test "carries original IFS within hooks" {
  create_hook rehash hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' run exenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "sh-rehash in bash" {
  create_executable "2.0" "elixir"
  EXENV_SHELL=bash run exenv-sh-rehash
  assert_success "hash -r 2>/dev/null || true"
  assert [ -x "${EXENV_ROOT}/shims/elixir" ]
}

@test "sh-rehash in fish" {
  create_executable "2.0" "elixir"
  EXENV_SHELL=fish run exenv-sh-rehash
  assert_success ""
  assert [ -x "${EXENV_ROOT}/shims/elixir" ]
}
