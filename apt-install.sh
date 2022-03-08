#!/bin/sh

set -eu

apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get \
        --no-install-recommends \
        --quiet \
        --yes \
        install \
        "$@"