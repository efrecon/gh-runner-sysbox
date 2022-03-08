#!/bin/sh

set -eu

# Use the GitHub homepage, and not the API, to get the latest sharp version of a
# project. This bypasses rate-limiting restrictions.

# Root GitHub home page
VERSION_GITHUB=${VERSION_GITHUB:-"https://github.com/"}

# Command to use to download a URL passed as a parameter and print out its
# content to stdout. The default is an empty string, which will use wget or
# curl, if present.
VERSION_DOWNLOAD=${VERSION_DOWNLOAD:-""}

# Are we running from a GitHub Workflow/Action. This should be 1 or 0. Empty
# (the default) means automatic detection.
VERSION_WORKFLOW=${VERSION_WORKFLOW:-""}

if [ -z "$VERSION_DOWNLOAD" ]; then
  if command -v wget >/dev/null 2>&1; then
    VERSION_DOWNLOAD="wget -q -O -"
  elif command -v curl >/dev/null 2>&1; then
    VERSION_DOWNLOAD="curl -sSL"
  else
    echo "Cannot find an external tool for URL downloads!" >&2
    exit 1
  fi
fi

if [ -z "$VERSION_WORKFLOW" ]; then
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    VERSION_WORKFLOW=1
  else
    VERSION_WORKFLOW=0
  fi
fi

version() {
  # This works on the HTML from GitHub as follows:
  # 1. Start from the list of tags, they point to the corresponding release.
  # 2. Extract references to the release page, force a possible v and a number
  #    at start of sub-path
  # 3. Use slash and quote as separators and extract the tag/release number with
  #    awk. This is a bit brittle.
  # 4. Remove leading v, if there is one (there will be in most cases!)
  # 5. Extract only pure SemVer sharp versions
  # 6. Just keep the top one, i.e. the latest release.
  ${VERSION_DOWNLOAD} "${VERSION_GITHUB}/${1}/tags"|
    grep -E "<a href=\"/${1}/releases/tag/v?[0-9]" |
    awk -F'[/\"]' '{print $7}' |
    sed 's/^v//g' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    head -1
}

for proj; do
  if [ "$VERSION_WORKFLOW" = "1" ]; then
    version=$(version "$proj")
    # Set an output named after the basename of the project, e.g. git-version
    printf '::set-output name=%s-version::%s\n' "$(basename "$proj")" "$version"
    # Set another output just called version, to simplify logic when this is
    # called with a single project name.
    printf '::set-output name=version::%s\n' "$version"
    # Set an environment variable called PROJ_VERSION where PROJ is the basename
    # of the project in uppercase.
    printf '%s_VERSION=%s\n' "$(basename "$proj" | tr '[:lower:]' '[:upper:]')" "$version" >> "${GITHUB_ENV:-/dev/stdout}"
  else
    version "$proj"
  fi
done
