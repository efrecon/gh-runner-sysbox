#!/bin/sh

set -eu

# Versions of Docker compose and the (new) shim to install. This can be
# `latest`: the latest release. This can also be a SemVer.
COMPOSE_VERSION=${COMPOSE_VERSION:-"latest"}
COMPOSE_SWITCH_VERSION=${COMPOSE_SWITCH_VERSION:-"latest"}

# Root projects locations
COMPOSE_GITHUB=${COMPOSE_GITHUB:-"https://github.com/"}
COMPOSE_ROOT=${COMPOSE_ROOT:-"${COMPOSE_GITHUB%/}/docker/compose"}
COMPOSE_SWITCH_ROOT=${COMPOSE_SWITCH_ROOT:-"${COMPOSE_GITHUB%/}/docker/compose-switch"}

# Root directory where to place Docker plugins, system-wide
COMPOSE_CLI_ROOT=${COMPOSE_CLI_ROOT:-"/usr/lib/docker/cli-plugins"}

# Command to use to download a URL passed as a parameter and print out its
# content to stdout. The default is an empty string, which will use wget or
# curl, if present.
COMPOSE_DOWNLOAD=${COMPOSE_DOWNLOAD:-""}

# Destination directory. This should be an existing directory that will be in
# the PATH.
COMPOSE_DESTINATION=${COMPOSE_DESTINATION:-"/usr/local/bin"}

while getopts "s:c:h-" opt; do
  case "$opt" in
    s) # Compose switch version
      COMPOSE_SWITCH_VERSION=$OPTARG;;
    c) # Docker compose version
      COMPOSE_VERSION=$OPTARG;;
    h) # Print help and exit
      echo "install docker compose (old and new)";;
    -)
      break;;
    *)
      echo "Unknown option";;
  esac
done
shift $((OPTIND-1))

dependency() {
  # shellcheck disable=SC3043 # local is implemented in almost all shells
  local prg || true

  prg=$1
  shift

  if command -v "${prg}.sh" >/dev/null 2>&1; then
    "${prg}.sh" "$@"
  else
    "$(dirname "$0")/${prg}.sh" "$@"
  fi
}

# Decide upon a tool for downloads
if [ -z "$COMPOSE_DOWNLOAD" ]; then
  if command -v wget >/dev/null 2>&1; then
    COMPOSE_DOWNLOAD="wget -q -O -"
  elif command -v curl >/dev/null 2>&1; then
    COMPOSE_DOWNLOAD="curl -sSL"
  else
    echo "Cannot find an external tool for URL downloads!" >&2
    exit 1
  fi
fi

# Decide version of compose
if [ "$COMPOSE_VERSION" = "latest" ]; then
  COMPOSE_VERSION=$(dependency version "docker/compose")
fi

if [ "${COMPOSE_VERSION%%.*}" -ge "2" ]; then
  # When this is the new v2 of compose, it will be located under one of the
  # recognised CLI plugins locations (we choose a system-wide one). Install it
  # there, and also install the docker-compose shim to /usr/local/bin.
  mkdir -p "$COMPOSE_CLI_ROOT"
  url=${COMPOSE_ROOT%/}/releases/download/v${COMPOSE_VERSION#v*}/docker-compose-$(uname -s|tr '[:upper:]' '[:lower:]')-$(uname -m)
  $COMPOSE_DOWNLOAD "$url" > "${COMPOSE_CLI_ROOT%/}/docker-compose"
  chmod a+x "${COMPOSE_CLI_ROOT%/}/docker-compose"

  # Decide version of shim
  if [ "$COMPOSE_SWITCH_VERSION" = "latest" ]; then
    COMPOSE_SWITCH_VERSION=$(dependency version "docker/compose-switch")
  fi

  url=${COMPOSE_SWITCH_ROOT%/}/releases/download/v${COMPOSE_SWITCH_VERSION#v*}/docker-compose-$(uname -s|tr '[:upper:]' '[:lower:]')-$(dependency arch -e 1)
  $COMPOSE_DOWNLOAD "$url" > "${COMPOSE_DESTINATION%/}/docker-compose"
  chmod a+x "${COMPOSE_DESTINATION%/}/docker-compose"
else
  # Old compose, just one binary
  url=${COMPOSE_ROOT%/}/releases/download/${COMPOSE_VERSION#v*}/docker-compose-$(uname -s)-$(uname -m)
  $COMPOSE_DOWNLOAD "$url" > "${COMPOSE_DESTINATION%/}/docker-compose"
  chmod a+x "${COMPOSE_DESTINATION%/}/docker-compose"
fi

# Print out the installed version, this is to make sure we got the binaries right.
docker-compose --version