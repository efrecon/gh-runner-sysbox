#!/bin/sh

set -eu

# This exports the environment to the file passed as an argument (stdout when
# none given). "private" environment variables, and variables that are not in
# uppercase are prevented from the export.

# | separated list of regexp for variables that should be prevented from the
# export.
EXPORT_PREVENT=${EXPORT_PREVENT:-"CWD|HOME|HOSTNAME|KUBERNETES_.*|LANG|LS_COLORS|PATH|PWD|SHELL|SSH_.*|TERM|USER|XDG_.*|_"}

# Name of the user to give the file for access. The file will be restricted for
# read/write by this user only.
EXPORT_USER=${EXPORT_USER:-"$(id -nu)"}

# PID to get environment from, empty means current environment instead
EXPORT_PID=${EXPORT_PID:-""}

while getopts "x:u:p:h-" opt; do
  case "$opt" in
    x) # Exclusion list
      EXPORT_PREVENT=$OPTARG;;
    u) # User to give away file to
      EXPORT_USER=$OPTARG;;
    p) # PID to get environment from
      EXPORT_PID=$OPTARG;;
    h) # Print help and exit
      echo "Export relevant environment to conf file";;
    -)
      break;;
    *)
      echo "Unknown option";;
  esac
done
shift $((OPTIND-1))

dumpenv() {
  if [ -z "$EXPORT_PID" ]; then
    env
  else
    xargs -0 -l1 echo < "/proc/${EXPORT_PID}/environ"
  fi
}

# Create directory to file, if necessary
if [ "$#" -gt "0" ]; then
  mkdir -p "$(dirname "$1")"
fi

# Export selected part of the environment
dumpenv | grep -E -e '^[A-Z_]+=' | grep -E -v "^(${EXPORT_PREVENT})=" > "${1:-/dev/stdout}"

# Prevent access to file
if [ "$#" -gt "0" ]; then
  chmod go-rwx,u+rw "$1"
  chown "$EXPORT_USER" "$1" || true
fi