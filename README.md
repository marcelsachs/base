# base

```
git -C /base pull && sudo nixos-rebuild switch --flake /base#blackwell
```

```
nix flake update tinygrad --flake /base && sudo nixos-rebuild switch --flake /base#blackwell
```

```
nix shell nixpkgs#git -c git clone https://github.com/marcelsachs/base /tmp/base && sudo /tmp/base/install.sh
```

`/etc/nixos` is a symlink to `/base`.
