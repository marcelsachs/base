#!/usr/bin/env bash
# Run from the Determinate NixOS live ISO, as root:
#   mkdir -p /usb
#   mount -t exfat /dev/mapper/sda1 /usb
#   bash /usb/nix/install.sh
#
# Both Ventoy labels are "Ventoy". 32GB is FBDE-EAD7. 500GB is 2680-E05F.
#
# Wipes nvme0n1: 1G ESP (label boot) + ext4 root (label nixos) + 32G swapfile.
# Copies this directory to /mnt/etc/nixos, adds sibling st/ blobs into
# the target store, nixos-installs #blackwell.
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }

DISK=/dev/nvme0n1
HERE=$(cd "$(dirname "$0")" && pwd)
[[ $HERE == /usb/nix ]] || { echo "mount usb at /usb" >&2; exit 1; }
STDIR=$(cd "$HERE/../st" && pwd)
CUBE="$STDIR/SetupSTM32CubeProgrammer_linux_64.zip"
EDGE="$STDIR/stedgeai-linux-offline"
KEY="$HERE/../secrets/id_ed25519"
[[ -f $CUBE ]] || { echo "st: missing $CUBE" >&2; exit 1; }
[[ -f $EDGE ]] || { echo "st: missing $EDGE" >&2; exit 1; }
[[ -f $KEY ]] || { echo "secrets: missing $KEY" >&2; exit 1; }

sgdisk -Z "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:boot -n 2:0:0 -t 2:8304 -c 2:nixos "$DISK"
partprobe "$DISK"
udevadm settle --timeout=15
mkfs.fat -F32 -n boot "${DISK}p1"
mkfs.ext4 -q -F -L nixos -E nodiscard "${DISK}p2"
partprobe "$DISK"
udevadm settle --timeout=15
# Mount by node, not by-label: udev labels lag after wipe.
mount "${DISK}p2" /mnt
mount --mkdir "${DISK}p1" /mnt/boot

mkdir -p /mnt/etc/nixos
cp -a "$HERE"/. /mnt/etc/nixos/
rm -rf /mnt/etc/nixos/.git
chmod -R u+w /mnt/etc/nixos

echo "st: add vendor blobs to /mnt store"
nix --extra-experimental-features nix-command --store /mnt \
  store add --mode flat --hash-algo sha256 --name "$(basename "$CUBE")" "$CUBE"
nix --extra-experimental-features nix-command --store /mnt \
  store add --mode flat --hash-algo sha256 --name "$(basename "$EDGE")" "$EDGE"

nixos-install --no-root-passwd --flake /mnt/etc/nixos#blackwell \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=

install -d -m 700 -o 1000 -g 100 /mnt/sachs/.ssh
install -m 600 -o 1000 -g 100 "$KEY" /mnt/sachs/.ssh/id_ed25519
install -m 644 -o 1000 -g 100 "$KEY.pub" /mnt/sachs/.ssh/id_ed25519.pub

echo "installed. reboot. sway."
