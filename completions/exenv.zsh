if [[ ! -o interactive ]]; then
    return
fi

compctl -K _exenv exenv

_exenv() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(exenv commands)"
  else
    completions="$(exenv completions ${words[2,-2]})"
  fi

  reply=("${(ps:\n:)completions}")
}
