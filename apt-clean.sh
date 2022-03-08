#!/bin/sh

# Clean apt and remove all downloaded caches.

set -eu

apt-get clean -y
rm -rf                                                             \
    /var/cache/debconf/*                                           \
    /var/lib/apt/lists/*                                           \
    /var/log/*                                                     \
    /tmp/*                                                         \
    /var/tmp/*                                                     \
    /usr/share/doc/*                                               \
    /usr/share/man/*                                               \
    /usr/share/local/*