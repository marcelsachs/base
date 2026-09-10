# base

Boot `ISO/nixos-with-determinate.iso`.

```
sudo bash -c 'mkdir -p /usb && mount /dev/mapper/sda1 /usb && bash /usb/nix/install.sh'
```

Stick layout, checked by `install.sh`:

```
nix/                      this checkout
st/                       SetupSTM32CubeProgrammer_linux_64.zip, stedgeai-linux-offline
secrets/                  id_ed25519, id_ed25519.pub, password.hash, tailscale.key, cache.key
home/.config/sway/bg      wallpaper
cache/                    optional: signed binary cache written by cache.sh
```

On the machine, after a rebuild worth keeping offline:

```
sudo mount /dev/sda1 /usb && sudo /etc/nixos/cache.sh && sudo umount /usb
```
