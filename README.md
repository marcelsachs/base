# base

```
git -C /etc/nixos pull && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
nix flake update tinygrad --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
nix shell nixpkgs#git -c git clone https://github.com/marcelsachs/base /tmp/base && sudo /tmp/base/install.sh
```
