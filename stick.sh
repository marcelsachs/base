#!/usr/bin/env bash
# Make the stick match this machine: checkout, signed binary cache, signing key.
# install.sh installs whatever commit is on the stick, so run this before a reinstall.
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -d /usb/nix/.git ]] || { echo "mount usb at /usb (with nix/ a git checkout)" >&2; exit 1; }
KEY=/var/lib/secrets/cache.key
[[ -f $KEY ]] || { echo "missing $KEY (umask 077; nix key generate-secret --key-name blackwell > $KEY)" >&2; exit 1; }

want=$(nix eval --raw /etc/nixos#nixosConfigurations.blackwell.config.system.build.toplevel.outPath)
have=$(readlink -f /run/current-system)
[[ $want == "$have" ]] || { echo "/etc/nixos is not what runs; nixos-rebuild switch first" >&2; exit 1; }

git -c safe.directory='*' -C /usb/nix fetch -q /etc/nixos master
git -c safe.directory='*' -C /usb/nix reset -q --hard FETCH_HEAD
echo "nix: $(git -c safe.directory='*' -C /usb/nix log --oneline -1)"

TO="file:///usb/cache?compression=zstd&secret-key=$KEY"
rm -rf /usb/cache
nix copy --to "$TO" /run/current-system
nix flake archive --to "$TO" /etc/nixos
cp "$KEY" /usb/secrets/cache.key
du -sh /usb/cache
