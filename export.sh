#!/bin/sh

set -eu

# This exports the environment to the file passed as an argument (stdout when
# none given). "private" environment variables, and variables that are not in
# uppercase are prevented from the export.

# | separated list of regexp for variables that should be prevented from the
# export.
EXPORT_PREVENT=${EXPORT_PREVENT:-"CWD|HOME|HOSTNAME|KUBERNETES_.*|LANG|LS_COLORS|PATH|PWD|SHELL|SSH_.*|TERM|USER|XDG_.*|_"}

env | grep -E -e '^[A-Z_]+=' | grep -E -v "^(${EXPORT_PREVENT})=" > "${1:-/dev/stdout}"
