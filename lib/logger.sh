#!/bin/sh

__LOG() {
    printf '[%s] [%s] [%s] %s\n' "$(date +'%Y%m%d-%H%M%S')" "${1:-LOG}" "$(basename "$0")" "${2:-}" >&2
}

INFO() { __LOG INFO "$1"; }
DEBUG() { __LOG DEBUG "$1"; }
ERROR() { __LOG ERROR "$1"; }
