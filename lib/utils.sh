#!/bin/sh

# Execute all programs present in the colon separated list of directories passed
# as $1. Executables are executed in alphabetical order.
execute() {
  printf %s\\n "$1" |
    sed 's/:/\n/g' |
    grep -vE '^$' |
    while IFS= read -r dir
    do
      if [ -d "$dir" ]; then
        INFO "Executing all files directly under '$dir', in alphabetical order"
        find -L "$dir" -maxdepth 1 -mindepth 1 -name '*' -type f -executable |
          sort |
          while IFS= read -r initfile
          do
            INFO "Executing $initfile"
            "$initfile"
          done
      fi
    done
}