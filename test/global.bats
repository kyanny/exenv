#!/usr/bin/env bats

load test_helper

@test "default" {
  run exenv-global
  assert_success
  assert_output "system"
}

@test "read EXENV_ROOT/version" {
  mkdir -p "$EXENV_ROOT"
  echo "1.2.3" > "$EXENV_ROOT/version"
  run exenv-global
  assert_success
  assert_output "1.2.3"
}

@test "set EXENV_ROOT/version" {
  mkdir -p "$EXENV_ROOT/versions/1.2.3"
  run exenv-global "1.2.3"
  assert_success
  run exenv-global
  assert_success "1.2.3"
}

@test "fail setting invalid EXENV_ROOT/version" {
  mkdir -p "$EXENV_ROOT"
  run exenv-global "1.2.3"
  assert_failure "exenv: version \`1.2.3' not installed"
}
