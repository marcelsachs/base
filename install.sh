#!/usr/bin/env bash
set -euo pipefail
((EUID == 0)) || { echo "run as root" >&2; exit 1; }
command -v git >/dev/null || exec nix shell nixpkgs#git -c "$0" "$@"
git() { command git -c safe.directory='*' "$@"; }

DISK=/dev/nvme0n1
USB=/usb
HERE=$(cd "$(dirname "$0")" && pwd)
[[ -d $HERE/.git ]] || { echo "not a git checkout: $HERE" >&2; exit 1; }

opened=
cleanup() {
  case $opened in
  ventoy) umount "$USB" ;;
  luks) umount "$USB" && cryptsetup close usb ;;
  esac
}
trap cleanup EXIT

if ! mountpoint -q "$USB"; then
  if [[ -e /dev/disk/by-label/Ventoy ]]; then
    mount --mkdir /dev/disk/by-label/Ventoy "$USB"
    opened=ventoy
  else
    mapfile -t luks < <(blkid -t TYPE=crypto_LUKS -o device)
    if ((${#luks[@]} == 1)); then
      [[ -e /dev/mapper/usb ]] || cryptsetup open "${luks[0]}" usb
      mount --mkdir /dev/mapper/usb "$USB"
      opened=luks
    fi
  fi
fi

attr=blackwell-bare
if mountpoint -q "$USB"; then
  attr=blackwell
  for f in \
    "$USB"/secrets/password.hash \
    "$USB"/secrets/tailscale.key \
    "$USB"/home/.ssh/id_ed25519 \
    "$USB"/home/.ssh/id_ed25519.pub \
    "$USB"/home/.config/gh/hosts.yml \
    "$USB"/home/.config/sway/bg \
    "$USB"/st/SetupSTM32CubeProgrammer_linux_64.zip \
    "$USB"/st/stedgeai-linux-offline; do
    if [[ ! -e $f ]]; then
      echo "missing $f"
      attr=blackwell-bare
      break
    fi
  done
fi
if [[ $attr == blackwell-bare ]]; then
  cleanup
  opened=
fi

read -rp "wipe $DISK, $attr $(git -C "$HERE" log -1 --format='%h %s'). Enter / Ctrl-C. "

sgdisk -Z "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:boot -n 2:0:0 -t 2:8304 -c 2:nixos "$DISK"
partprobe "$DISK"
udevadm settle --timeout=15
mkfs.fat -F32 -n boot "${DISK}p1"
mkfs.ext4 -q -F -L nixos -E nodiscard "${DISK}p2"

mount "${DISK}p2" /mnt
mount -o fmask=0077,dmask=0077 --mkdir "${DISK}p1" /mnt/boot

git clone -- "$HERE" /mnt/etc/nixos
git -C /mnt/etc/nixos remote set-url origin git@github.com:marcelsachs/base.git

if [[ $attr == blackwell ]]; then
  install -D -m 600 "$USB"/secrets/password.hash /mnt/var/lib/secrets/password.hash
  install -D -m 600 "$USB"/secrets/tailscale.key /mnt/var/lib/secrets/tailscale.key
  mkdir -p /mnt/home/sachs
  cp -a "$USB"/home/. /mnt/home/sachs/
  chmod 700 /mnt/home/sachs/.ssh /mnt/home/sachs/.config/gh
  chmod 600 /mnt/home/sachs/.ssh/id_ed25519 /mnt/home/sachs/.config/gh/hosts.yml
  nix-store --store /mnt --add-fixed sha256 "$USB"/st/SetupSTM32CubeProgrammer_linux_64.zip
  nix-store --store /mnt --add-fixed sha256 "$USB"/st/stedgeai-linux-offline
fi

nixos-install --no-root-passwd --flake /mnt/etc/nixos#$attr \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=

chown -R 1000:100 /mnt/etc/nixos
[[ -d /mnt/home/sachs ]] && chown -R 1000:100 /mnt/home/sachs
