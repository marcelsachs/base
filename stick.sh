#!/usr/bin/env bash
# Update nix/ on the stick to the commit this machine runs.
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -d /usb/nix/.git ]] || { echo "mount usb at /usb" >&2; exit 1; }
git -c safe.directory='*' -C /usb/nix fetch -q /etc/nixos master
git -c safe.directory='*' -C /usb/nix reset -q --hard FETCH_HEAD
echo "stick: $(git -c safe.directory='*' -C /usb/nix log --oneline -1)"
