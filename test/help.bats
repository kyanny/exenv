#!/usr/bin/env bats

load test_helper

@test "without args shows summary of common commands" {
  run exenv-help
  assert_success
  assert_line "Usage: exenv <command> [<args>]"
  assert_line "Some useful exenv commands are:"
}

@test "invalid command" {
  run exenv-help hello
  assert_failure "exenv: no such command \`hello'"
}

@test "shows help for a specific command" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  cat > "${EXENV_TEST_DIR}/bin/exenv-hello" <<SH
#!shebang
# Usage: exenv hello <world>
# Summary: Says "hello" to you, from exenv
# This command is useful for saying hello.
echo hello
SH

  run exenv-help hello
  assert_success
  assert_output <<SH
Usage: exenv hello <world>

This command is useful for saying hello.
SH
}

@test "replaces missing extended help with summary text" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  cat > "${EXENV_TEST_DIR}/bin/exenv-hello" <<SH
#!shebang
# Usage: exenv hello <world>
# Summary: Says "hello" to you, from exenv
echo hello
SH

  run exenv-help hello
  assert_success
  assert_output <<SH
Usage: exenv hello <world>

Says "hello" to you, from exenv
SH
}

@test "extracts only usage" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  cat > "${EXENV_TEST_DIR}/bin/exenv-hello" <<SH
#!shebang
# Usage: exenv hello <world>
# Summary: Says "hello" to you, from exenv
# This extended help won't be shown.
echo hello
SH

  run exenv-help --usage hello
  assert_success "Usage: exenv hello <world>"
}

@test "multiline usage section" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  cat > "${EXENV_TEST_DIR}/bin/exenv-hello" <<SH
#!shebang
# Usage: exenv hello <world>
#        exenv hi [everybody]
#        exenv hola --translate
# Summary: Says "hello" to you, from exenv
# Help text.
echo hello
SH

  run exenv-help hello
  assert_success
  assert_output <<SH
Usage: exenv hello <world>
       exenv hi [everybody]
       exenv hola --translate

Help text.
SH
}

@test "multiline extended help section" {
  mkdir -p "${EXENV_TEST_DIR}/bin"
  cat > "${EXENV_TEST_DIR}/bin/exenv-hello" <<SH
#!shebang
# Usage: exenv hello <world>
# Summary: Says "hello" to you, from exenv
# This is extended help text.
# It can contain multiple lines.
#
# And paragraphs.

echo hello
SH

  run exenv-help hello
  assert_success
  assert_output <<SH
Usage: exenv hello <world>

This is extended help text.
It can contain multiple lines.

And paragraphs.
SH
}
