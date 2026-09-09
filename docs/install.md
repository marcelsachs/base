# Install

Boot `ISO/nixos-with-determinate.iso` from the Ventoy stick. Both disks are
labeled Ventoy. 32GB is UUID `FBDE-EAD7`. 500GB is `2680-E05F`. On the live
console:

```
sudo bash -c 'mkdir -p /mnt/usb && mount /dev/disk/by-uuid/FBDE-EAD7 /mnt/usb && bash /mnt/usb/nix/install.sh'
```

Partitions nvme0n1, copies `nix/` to `/mnt/etc/nixos`, adds `st/` blobs to
the target store, `nixos-install`s `#blackwell`. Do not type `sgdisk` by hand.

OS only. Empty desks. Then `bootstrap.sh` (drone/sentry + LFS).
tinygrad: clone upstream into `/tinygrad`.
Boot: Sway. Seat sachs. `n6 load ELF` on a plugged board.
`stprogr` and `stedgeai` are on PATH.

After reboot, on the box:

```
bash /etc/nixos/bootstrap.sh
```

`bootstrap.sh` clones drone/sentry and `git lfs pull`.

tinygrad: clone upstream into `/tinygrad`, then `gpu`.

Prove, in order: Sway → `lsmod | grep nvidia` → `/dev/nvidia0` → ST-LINK udev → `n6 check` → `stprogr --version` → `stedgeai --version`.
