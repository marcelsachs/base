#!/usr/bin/env bash
# Copy the running system and the flake inputs to the stick, signed.
# With that, install.sh needs no downloads for a system at this commit.
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -d /usb/nix ]] || { echo "mount usb at /usb" >&2; exit 1; }
KEY=/var/lib/secrets/cache.key
[[ -f $KEY ]] || { echo "missing $KEY (umask 077; nix key generate-secret --key-name blackwell > $KEY)" >&2; exit 1; }

TO="file:///usb/cache?compression=zstd&secret-key=$KEY"
rm -rf /usb/cache
nix copy --to "$TO" /run/current-system
nix flake archive --to "$TO" /etc/nixos
cp "$KEY" /usb/secrets/cache.key
du -sh /usb/cache
