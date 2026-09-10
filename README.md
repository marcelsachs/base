# base

```
git -C /etc/nixos pull && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
nix flake update tinygrad --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
sudo bash -c 'mkdir -p /usb && mount /dev/mapper/sda1 /usb && bash /usb/nix/install.sh'
```

```
sudo git -c safe.directory='*' -C /usb/nix fetch -q /etc/nixos master && sudo git -c safe.directory='*' -C /usb/nix reset -q --hard FETCH_HEAD
```
