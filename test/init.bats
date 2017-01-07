#!/usr/bin/env bats

load test_helper

@test "creates shims and versions directories" {
  assert [ ! -d "${EXENV_ROOT}/shims" ]
  assert [ ! -d "${EXENV_ROOT}/versions" ]
  run exenv-init -
  assert_success
  assert [ -d "${EXENV_ROOT}/shims" ]
  assert [ -d "${EXENV_ROOT}/versions" ]
}

@test "auto rehash" {
  run exenv-init -
  assert_success
  assert_line "command exenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run exenv-init - bash
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/exenv.bash'"
}

@test "detect parent shell" {
  SHELL=/bin/false run exenv-init -
  assert_success
  assert_line "export EXENV_SHELL=bash"
}

@test "detect parent shell from script" {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
  cat > myscript.sh <<OUT
#!/bin/sh
eval "\$(exenv-init -)"
echo \$EXENV_SHELL
OUT
  chmod +x myscript.sh
  run ./myscript.sh /bin/zsh
  assert_success "sh"
}

@test "setup shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run exenv-init - fish
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/exenv.fish'"
}

@test "fish instructions" {
  run exenv-init fish
  assert [ "$status" -eq 1 ]
  assert_line 'status --is-interactive; and source (exenv init -|psub)'
}

@test "option to skip rehash" {
  run exenv-init - --no-rehash
  assert_success
  refute_line "exenv rehash 2>/dev/null"
}

@test "adds shims to PATH" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run exenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${EXENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run exenv-init - fish
  assert_success
  assert_line 0 "setenv PATH '${EXENV_ROOT}/shims' \$PATH"
}

@test "can add shims to PATH more than once" {
  export PATH="${EXENV_ROOT}/shims:$PATH"
  run exenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${EXENV_ROOT}'/shims:${PATH}"'
}

@test "can add shims to PATH more than once (fish)" {
  export PATH="${EXENV_ROOT}/shims:$PATH"
  run exenv-init - fish
  assert_success
  assert_line 0 "setenv PATH '${EXENV_ROOT}/shims' \$PATH"
}

@test "outputs sh-compatible syntax" {
  run exenv-init - bash
  assert_success
  assert_line '  case "$command" in'

  run exenv-init - zsh
  assert_success
  assert_line '  case "$command" in'
}

@test "outputs fish-specific syntax (fish)" {
  run exenv-init - fish
  assert_success
  assert_line '  switch "$command"'
  refute_line '  case "$command" in'
}
