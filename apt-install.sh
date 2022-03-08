#!/bin/sh

# This is an apt install wrapper that updates the package DB first, before
# installing quietly and without recommended dependencies.

set -eu

apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get \
        --no-install-recommends \
        --quiet \
        --yes \
        install \
        "$@"