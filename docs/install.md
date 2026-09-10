# Install

Boot `ISO/nixos-with-determinate.iso`. Both disks label Ventoy. 32GB UUID `FBDE-EAD7`. 500GB `2680-E05F`.

```
sudo bash -c 'mkdir -p /usb && mount -t exfat /dev/mapper/sda1 /usb && bash /usb/nix/install.sh'
```

Wipes nvme0n1. Copies `nix/` to `/mnt/etc/nixos`. Adds `st/` to the target store. `nixos-install #blackwell`.

After reboot:

```
bash /etc/nixos/bootstrap.sh
```

Clones lab/drone/sentry + LFS. tinygrad: clone upstream into `/tinygrad`.
