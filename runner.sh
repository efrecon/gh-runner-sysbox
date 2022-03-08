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

deregister_runner() {
  INFO "Caught SIGTERM. Deregistering runner"
  _TOKEN=$(token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  ./config.sh remove --token "${RUNNER_TOKEN}"

  # Call user-level cleanup processes
  if [ -n "${RUNNER_CLEANUP_PATH:-}" ]; then
    execute "$RUNNER_CLEANUP_PATH"
  fi

  exit
}

# Call user-level initialisation processes
if [ -n "${RUNNER_INIT_PATH:-}" ]; then
  execute "$RUNNER_INIT_PATH"
fi

_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-/actions-runner/_work}
_LABELS=${LABELS:-default}
_RUNNER_GROUP=${RUNNER_GROUP:-Default}
_SHORT_URL=${REPO_URL}
_GITHUB_HOST=${GITHUB_HOST:="github.com"}

if [ "${ORG_RUNNER}" = "true" ]; then
  _SHORT_URL="https://${_GITHUB_HOST}/${ORG_NAME}"
fi

if [ -n "${ACCESS_TOKEN}" ]; then
  _TOKEN=$(token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  _SHORT_URL=$(echo "${_TOKEN}" | jq -r .short_url)
fi

INFO "Configuring runner $_RUNNER_NAME (in group: $_RUNNER_GROUP), labels: $_LABELS"
./config.sh \
    --url "${_SHORT_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${_RUNNER_NAME}" \
    --work "${_RUNNER_WORKDIR}" \
    --labels "${_LABELS}" \
    --runnergroup "${_RUNNER_GROUP}" \
    --unattended \
    --replace

unset RUNNER_TOKEN
trap deregister_runner INT QUIT TERM

./bin/runsvc.sh