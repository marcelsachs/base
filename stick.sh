#!/usr/bin/env bash
# Put this machine's /etc/nixos commit on the stick. install.sh installs whatever is there.
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -d /usb/nix/.git ]] || { echo "mount usb at /usb (with nix/ a git checkout)" >&2; exit 1; }
git -c safe.directory='*' -C /usb/nix fetch -q /etc/nixos master
git -c safe.directory='*' -C /usb/nix reset -q --hard FETCH_HEAD
echo "nix: $(git -c safe.directory='*' -C /usb/nix log --oneline -1)"
