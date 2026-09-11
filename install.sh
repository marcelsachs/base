#!/usr/bin/env bash
set -euo pipefail
SECONDS=0
[[ $(id -u) -eq 0 ]] || { echo "run as root" >&2; exit 1; }
command -v git >/dev/null || exec nix shell nixpkgs#git -c "$0" "$@"
git() { command git -c safe.directory='*' "$@"; }

DISK=/dev/nvme0n1
USB=/usb
HERE=$(cd "$(dirname "$0")" && pwd)
[[ -d $HERE/.git ]] || { echo "nix: $HERE is not a git checkout" >&2; exit 1; }

opened=
if ! mountpoint -q "$USB"; then
  mapfile -t luks < <(blkid -t TYPE=crypto_LUKS -o device)
  ((${#luks[@]} == 1)) || { echo "usb: found ${#luks[@]} LUKS devices (${luks[*]:-none}), mount the stick at $USB yourself" >&2; exit 1; }
  [[ -e /dev/mapper/usb ]] || cryptsetup open "${luks[0]}" usb
  mount --mkdir /dev/mapper/usb "$USB"
  opened=1
fi
KEY=$USB/secrets/id_ed25519
PW=$USB/secrets/password.hash
TS=$USB/secrets/tailscale.key
GH=$USB/secrets/github.token
BG=$USB/home/.config/sway/bg
[[ -f $KEY ]] || { echo "secrets: missing $KEY" >&2; exit 1; }
[[ -f $PW ]] || { echo "secrets: missing $PW (mkpasswd -m sha-512 > $PW)" >&2; exit 1; }
[[ -f $TS ]] || { echo "secrets: missing $TS (reusable, pre-approved tailscale auth key)" >&2; exit 1; }
[[ -f $GH ]] || { echo "secrets: missing $GH (classic PAT, no expiry, scopes: repo read:org workflow gist)" >&2; exit 1; }
[[ -f $BG ]] || { echo "home: missing $BG (the wallpaper)" >&2; exit 1; }
read -rp "nix: $(git -C "$HERE" log -1 --date=format:'%F %R' --format='%h %cd %s'). Enter to install, Ctrl-C to stop. "

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
git -C /mnt/etc/nixos remote set-url origin git@github.com:marcelsachs/base.git
install -D -m 600 "$PW" /mnt/var/lib/secrets/password.hash
install -m 600 "$TS" /mnt/var/lib/secrets/tailscale.key

nixos-install --no-root-passwd --flake /mnt/etc/nixos#blackwell \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=

install -d -m 700 /mnt/home/sachs/.ssh
install -m 600 "$KEY" /mnt/home/sachs/.ssh/id_ed25519
install -m 644 "$KEY.pub" /mnt/home/sachs/.ssh/id_ed25519.pub
install -d -m 700 /mnt/home/sachs/.config/gh
tok=$(<"$GH")
(umask 077; cat > /mnt/home/sachs/.config/gh/hosts.yml <<EOF
github.com:
    user: marcelsachs
    oauth_token: $tok
    git_protocol: ssh
    users:
        marcelsachs:
            oauth_token: $tok
EOF
)
install -D -m 644 "$BG" /mnt/home/sachs/.config/sway/bg
chown -R 1000:100 /mnt/etc/nixos /mnt/home/sachs

if [[ $opened ]]; then umount "$USB" && cryptsetup close usb; fi
echo $SECONDS
