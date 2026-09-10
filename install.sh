#!/usr/bin/env bash
set -euo pipefail
SECONDS=0
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }

DISK=/dev/nvme0n1
HERE=$(cd "$(dirname "$0")" && pwd)
[[ $HERE == /usb/nix ]] || { echo "mount usb at /usb" >&2; exit 1; }
STDIR=$(cd "$HERE/../st" && pwd)
CUBE="$STDIR/SetupSTM32CubeProgrammer_linux_64.zip"
EDGE="$STDIR/stedgeai-linux-offline"
KEY="$HERE/../secrets/id_ed25519"
PW="$HERE/../secrets/password.hash"
TS="$HERE/../secrets/tailscale.key"
BG="$HERE/../home/.config/sway/bg"
[[ -f $CUBE ]] || { echo "st: missing $CUBE" >&2; exit 1; }
[[ -f $EDGE ]] || { echo "st: missing $EDGE" >&2; exit 1; }
[[ -f $KEY ]] || { echo "secrets: missing $KEY" >&2; exit 1; }
[[ -f $PW ]] || { echo "secrets: missing $PW (mkpasswd -m sha-512 > $PW)" >&2; exit 1; }
[[ -f $TS ]] || { echo "secrets: missing $TS (reusable, pre-approved tailscale auth key)" >&2; exit 1; }
[[ -f $BG ]] || { echo "home: missing $BG (the wallpaper)" >&2; exit 1; }
[[ -d $HERE/.git ]] || { echo "nix: $HERE is not a git checkout" >&2; exit 1; }
last=$(tail -1 "$HERE/.git/logs/HEAD")
when=$(date -d @"$(awk -F'\t' '{ n = split($1, a, " "); print a[n - 1] }' <<<"$last")" '+%F %R')
read -rp "nix: commit $(cut -c42-48 <<<"$last"), on the stick since $when. Enter to install, Ctrl-C to stop. "

sgdisk -Z "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:boot -n 2:0:0 -t 2:8304 -c 2:nixos "$DISK"
partprobe "$DISK"
udevadm settle --timeout=15
mkfs.fat -F32 -n boot "${DISK}p1"
mkfs.ext4 -q -F -L nixos -E nodiscard "${DISK}p2"
partprobe "$DISK"
udevadm settle --timeout=15
mount "${DISK}p2" /mnt
mount -o fmask=0077,dmask=0077 --mkdir "${DISK}p1" /mnt/boot

mkdir -p /mnt/etc/nixos
cp -a "$HERE"/. /mnt/etc/nixos/
install -D -m 600 "$PW" /mnt/var/lib/secrets/password.hash
install -m 600 "$TS" /mnt/var/lib/secrets/tailscale.key

echo "st: add vendor blobs to /mnt store"
nix --extra-experimental-features nix-command --store /mnt \
  store add --mode flat --hash-algo sha256 --name "$(basename "$CUBE")" "$CUBE"
nix --extra-experimental-features nix-command --store /mnt \
  store add --mode flat --hash-algo sha256 --name "$(basename "$EDGE")" "$EDGE"

nixos-install --no-root-passwd --flake /mnt/etc/nixos#blackwell \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=

install -d -m 700 /mnt/home/sachs/.ssh
install -m 600 "$KEY" /mnt/home/sachs/.ssh/id_ed25519
install -m 644 "$KEY.pub" /mnt/home/sachs/.ssh/id_ed25519.pub
install -D -m 644 "$BG" /mnt/home/sachs/.config/sway/bg
chown -R 1000:100 /mnt/etc/nixos /mnt/home/sachs

echo $SECONDS
