# base

```
git -C /etc/nixos pull && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

```
nix flake update tinygrad stm32n6 --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#blackwell
```

stprogr and stedgeai need ST's installers in the store. install.sh seeds them from the Ventoy
stick's st/ directory; on a running system, mount Ventoy, then:

```
nix-prefetch-url file:///usb/st/SetupSTM32CubeProgrammer_linux_64.zip
nix-prefetch-url file:///usb/st/stedgeai-linux-offline
```

```
nix shell nixpkgs#git -c git clone https://github.com/marcelsachs/base /tmp/base && sudo /tmp/base/install.sh
```
