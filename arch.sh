#!/bin/sh

# This is a translator for the result of uname -m, as various projects have
# different views on things, e.g. x86_64, x64, amd64 are used throughout.

set -eu

# Space separated list of architecture translation tokens. Each token uses the
# colon sign as a separator: left-hand side is the result of uname --m,
# right-hand side the translated architecture that will be printed out. When
# empty, the source will be printed out.
ARCH_TRANSLATE=${ARCH_TRANSLATE:-"x86_64:amd64 aarch64:arm64"}

# The exit code when the current architecture is unknown
ARCH_EXITCODE=${ARCH_EXITCODE:-1}

while getopts "t:e:h-" opt; do
  case "$opt" in
    e) # Exit code on unknown architectures.
      ARCH_EXITCODE=$OPTARG;;
    t) # List of arch translation tokens, colon separated
      ARCH_TRANSLATE=$OPTARG;;
    h) # Print help and exit
      echo "Translate the name of the current machine architecture" && exit ;;
    -)
      break;;
    *)
      echo "Unknown option";;
  esac
done
shift $((OPTIND-1))

current=$(uname --m)
for translate in $ARCH_TRANSLATE; do
  src=$(printf %s\\n "$translate" | cut -d: -f1)
  dst=$(printf %s\\n "$translate" | cut -d: -f2)
  if [ -z "$dst" ]; then
    dst=$src
  fi

  if [ "$current" = "$src" ]; then
    printf %s\\n "$dst"
    exit
  fi
done

# Only reached when no translation available
printf %s\\n "$current"
exit "$ARCH_EXITCODE"
