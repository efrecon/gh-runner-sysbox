#!/bin/sh

for d in "$(dirname "$0")/lib" /usr/local/share/runner; do
  if [ -d "$d" ]; then
    for m in logger; do
      # shellcheck disable=SC1090
      . "${d%/}/${m}.sh"
    done
    break
  fi
done

if [ "$#" = "0" ]; then
  ERROR "You must provide the type of the token to create"
  exit 1
fi

if printf %s\\n "$1" | grep -qE '\-token$'; then
  _TYPE=$1
else
  case "$1" in
    reg*)
      _TYPE=registration-token;;
    de* | un* | rem*)
      _TYPE=remove-token;;
    *)
      ERROR "$1 unknown token type" && exit 1;;
  esac
fi

_ORG_RUNNER=${ORG_RUNNER:-false}
_GITHUB_HOST=${GITHUB_HOST:="github.com"}

# If URL is not github.com then use the enterprise api endpoint
if [ "${GITHUB_HOST}" = "github.com" ]; then
    URI="https://api.${_GITHUB_HOST}"
else
    URI="https://${_GITHUB_HOST}/api/v3"
fi

API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"

REPO_URL=${REPO_URL:-${URI}}
_PROTO="$(echo "${REPO_URL}" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# shellcheck disable=SC2116
_URL=$(echo "$REPO_URL" | sed -E "s,^${_PROTO},,")
_PATH="$(echo "${_URL}" | grep / | cut -d/ -f2-)"
_ACCOUNT="$(echo "${_PATH}" | cut -d/ -f1)"
_REPO="$(echo "${_PATH}" | cut -d/ -f2)"

_FULL_URL="${URI}/repos/${_ACCOUNT}/${_REPO}/actions/runners/${_TYPE}"
if [ "${_ORG_RUNNER}" = "true" ]; then
  [ -z "${ORG_NAME:-}" ] && ( ERROR "ORG_NAME required for org runners"; exit 1 )
  _FULL_URL="${URI}/orgs/${ORG_NAME}/actions/runners/${_TYPE}"
  _SHORT_URL="${_PROTO}${_GITHUB_HOST}/${ORG_NAME}"
else
  _SHORT_URL=$REPO_URL
fi

RUNNER_TOKEN="$(curl -XPOST -fsSL \
  -H "${AUTH_HEADER}" \
  -H "${API_HEADER}" \
  "${_FULL_URL}" \
| jq -r '.token')"

echo "{\"token\": \"${RUNNER_TOKEN}\", \"short_url\": \"${_SHORT_URL}\", \"full_url\": \"${_FULL_URL}\"}"