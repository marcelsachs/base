# base

Changes: `git -C /etc/nixos pull && sudo nixos-rebuild switch --flake /etc/nixos#blackwell`.
A reinstall is only for testing `install.sh`.

## Reinstall

The stick installs the commit it has, so give it this machine's commit first:

```
sudo mount /dev/sda1 /usb && sudo /etc/nixos/stick.sh && sudo umount /usb
```

Boot `ISO/nixos-with-determinate.iso`, then:

```
sudo bash -c 'mkdir -p /usb && mount /dev/mapper/sda1 /usb && bash /usb/nix/install.sh'
```

Stick layout, checked by `install.sh`:

```
nix/                      this checkout
st/                       SetupSTM32CubeProgrammer_linux_64.zip, stedgeai-linux-offline
secrets/                  id_ed25519, id_ed25519.pub, password.hash, tailscale.key
home/.config/sway/bg      wallpaper
```
