# base

```
git -C /etc/nixos pull && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
sudo bash -c 'mkdir -p /usb && mount /dev/mapper/sda1 /usb && bash /usb/nix/install.sh'
```
