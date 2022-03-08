#!/bin/sh

set -eu

# Runner version to install. This can be `latest`: the latest release from the
# stable channel. This can also be a SemVer, possibly with a git sha at its end
# (dash separated), in which case the git sha is removed to get the version.
RUNNER_VERSION=${RUNNER_VERSION:-"latest"}

# Command to use to download a URL passed as a parameter and print out its
# content to stdout. The default is an empty string, which will use wget or
# curl, if present.
RUNNER_DOWNLOAD=${RUNNER_DOWNLOAD:-""}

# Destination directory. This should be an existing directory that will be in
# the PATH.
RUNNER_DESTINATION=${RUNNER_DESTINATION:-"."}

while getopts "v:h-" opt; do
  case "$opt" in
    v) # Docker version
      RUNNER_VERSION=$OPTARG;;
    h) # Print help and exit
      echo "install GH runner";;
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

# When latest version is specified, go and get the latest version of runner to
# build upon.
if [ "${RUNNER_VERSION}" = "latest" ] || printf %s\\n "${RUNNER_VERSION}" | grep -Eq '^[0-9a-f]{7}$'; then
  RUNNER_VERSION=$(dependency version "actions/runner")
fi

# When the version number ends with a git sha, remove that and build with the
# remaining version number.
if printf %s\\n "${RUNNER_VERSION}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]{7}$'; then
  RUNNER_VERSION=$(printf %s\\n "${RUNNER_VERSION}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+')
fi

# Decide upon a tool for downloads
if [ -z "$RUNNER_DOWNLOAD" ]; then
  if command -v wget >/dev/null 2>&1; then
    RUNNER_DOWNLOAD="wget -q -O -"
  elif command -v curl >/dev/null 2>&1; then
    RUNNER_DOWNLOAD="curl -sSL"
  else
    echo "Cannot find an external tool for URL downloads!" >&2
    exit 1
  fi
fi

# Decide which URL to get the tar from, this depends on the current
# architecture.
arch=$(dependency arch -t "x86_64:x64 aarch64:amd64" -e 1)
url=https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${arch}-${RUNNER_VERSION}.tar.gz

# Download and install
$RUNNER_DOWNLOAD "$url" > "actions-runner-linux-${arch}-${RUNNER_VERSION}.tar.gz"
tar \
  --extract \
  --file "actions-runner-linux-${arch}-${RUNNER_VERSION}.tar.gz" \
  --strip-components 1
rm -f "actions-runner-linux-${arch}-${RUNNER_VERSION}.tar.gz"
