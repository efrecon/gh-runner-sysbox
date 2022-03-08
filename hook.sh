#!/bin/sh

for d in "$(dirname "$0")/lib" /usr/local/share/runner; do
  if [ -d "$d" ]; then
    for m in logger utils; do
      # shellcheck disable=SC1090
      . "${d%/}/${m}.sh"
    done
    break
  fi
done

if [ "$#" -gt "0" ]; then
  # Extra precautious: We verify that the argument actually is the name of a
  # variable before we eval
  if set | grep -q "^${1}="; then
    execute "$(eval echo "\$${1}")"
  fi
fi
