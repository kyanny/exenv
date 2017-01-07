#!/usr/bin/env bats

load test_helper

create_executable() {
  name="${1?}"
  shift 1
  bin="${EXENV_ROOT}/versions/${EXENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

@test "fails with invalid version" {
  export EXENV_VERSION="2.0"
  run exenv-exec elixir -v
  assert_failure "exenv: version \`2.0' is not installed (set by EXENV_VERSION environment variable)"
}

@test "fails with invalid version set from file" {
  mkdir -p "$EXENV_TEST_DIR"
  cd "$EXENV_TEST_DIR"
  echo 1.9 > .elixir-version
  run exenv-exec rspec
  assert_failure "exenv: version \`1.9' is not installed (set by $PWD/.elixir-version)"
}

@test "completes with names of executables" {
  export EXENV_VERSION="2.0"
  create_executable "elixir" "#!/bin/sh"
  create_executable "mix" "#!/bin/sh"

  exenv-rehash
  run exenv-completions exec
  assert_success
  assert_output <<OUT
--help
mix
elixir
OUT
}

@test "carries original IFS within hooks" {
  create_hook exec hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export EXENV_VERSION=system
  IFS=$' \t\n' run exenv-exec env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "forwards all arguments" {
  export EXENV_VERSION="2.0"
  create_executable "elixir" <<SH
#!$BASH
echo \$0
for arg; do
  # hack to avoid bash builtin echo which can't output '-e'
  printf "  %s\\n" "\$arg"
done
SH

  run exenv-exec elixir -w "/path to/elixir script.exs" -- extra args
  assert_success
  assert_output <<OUT
${EXENV_ROOT}/versions/2.0/bin/elixir
  -w
  /path to/elixir script.exs
  --
  extra
  args
OUT
}

@test "supports elixir -S <cmd>" {
  export EXENV_VERSION="2.0"

  # emulate `elixir -S' behavior
  create_executable "elixir" <<SH
#!$BASH
if [[ \$1 == "-S"* ]]; then
  found="\$(PATH="\${RUBYPATH:-\$PATH}" which \$2)"
  # assert that the found executable has elixir for shebang
  if head -1 "\$found" | grep elixir >/dev/null; then
    \$BASH "\$found"
  else
    echo "elixir: no Elixir script found in input (LoadError)" >&2
    exit 1
  fi
else
  echo 'elixir 2.0 (exenv test)'
fi
SH

  create_executable "rake" <<SH
#!/usr/bin/env elixir
echo hello rake
SH

  exenv-rehash
  run elixir -S rake
  assert_success "hello rake"
}
