#!/usr/bin/bash
set -eou pipefail

[[ ${1-} == --?* ]] && password=${1#--} || password=root

SECONDS=0
exec > >(tee /tmp/base-install.log) 2>&1

disk=/dev/nvme0n1
hostname=blackwell
timezone=Europe/Berlin
locale=en_US.UTF-8
keymap=neoqwertz
username=sachs
home=/sachs
root_password=$password
user_password=$password

blkdiscard -f "$disk" 2>/dev/null
sgdisk -Z "$disk"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI \
       -n 2:0:0   -t 2:8300 -c 2:arch "$disk"
partprobe "$disk"
udevadm settle
mkfs.fat -F32 "${disk}p1"
mkfs.ext4 -F "${disk}p2"

mount "${disk}p2" /mnt
mount --mkdir "${disk}p1" /mnt/boot
mkswap -U clear --size 16G --file /mnt/swapfile
swapon /mnt/swapfile

reflector --country Germany --latest 10 --sort age \
          --protocol https --save /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm archlinux-keyring
pacstrap -K /mnt $(<packages.txt)
genfstab -U /mnt >>/mnt/etc/fstab

ln -sf "/usr/share/zoneinfo/$timezone" /mnt/etc/localtime
printf 'LANG=%s\n' "$locale" >/mnt/etc/locale.conf
printf 'KEYMAP=%s\n' "$keymap" >/mnt/etc/vconsole.conf
printf '%s\n' "$hostname" >/mnt/etc/hostname
printf '%s UTF-8\n' "$locale" >/mnt/etc/locale.gen
printf '%s\n' '%wheel ALL=(ALL:ALL) ALL' >/mnt/etc/sudoers.d/wheel
chmod 440 /mnt/etc/sudoers.d/wheel

install -Dm644 /dev/stdin /mnt/etc/iwd/main.conf <<'EOF'
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
install -Dm644 /dev/stdin /mnt/etc/systemd/network/20-wired.network <<'EOF'
[Match]
Name=en*

[Network]
DHCP=yes
EOF
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
install -Dm644 /dev/stdin /mnt/etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF

uuid=$(blkid -s UUID -o value "${disk}p2")
install -Dm644 /dev/stdin /mnt/boot/loader/loader.conf <<'EOF'
default arch.conf
timeout 0
console-mode keep
editor no
EOF
install -Dm644 /dev/stdin /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$uuid rw nowatchdog
EOF

useradd --root /mnt -m -d "$home" -G wheel,video,audio,render,input,lp,storage \
    -s /bin/bash "$username"
printf 'root:%s\n' "$root_password" | chpasswd --root /mnt
printf '%s:%s\n' "$username" "$user_password" | chpasswd --root /mnt
install -d -m 700 /mnt"$home"/.ssh
ssh-keygen -t ed25519 -f /mnt"$home"/.ssh/id_ed25519 -N '' -C "$username@$hostname"

cp -a . /mnt"$home"/base
find "/mnt$home/base/dotfiles" -type f -printf '%P\0' | while IFS= read -r -d '' r; do
  mkdir -p "/mnt$home/$(dirname "$r")"
  ln -sfn "$home/base/dotfiles/$r" "/mnt$home/$r"
done

systemctl --root=/mnt enable sshd iwd systemd-networkd systemd-resolved bluetooth tailscaled
arch-chroot /mnt bash -c 'locale-gen && hwclock --systohc && mkinitcpio -P && bootctl install'
echo "$SECONDS"
bash scripts/write-install-report.sh /tmp/base-install.log "/mnt$home/base/base-install-report.html" "$SECONDS"
chown -R 1000:1000 /mnt"$home"
