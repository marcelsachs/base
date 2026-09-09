# base

NixOS flake for this STM32N6 workstation. Machine hostname `blackwell`.
Power-on is Sway. Seat `sachs`. HOME=/sachs. Root is rebuild and SSH.

```
/etc/nixos     this flake
/drone         Sequre H743 + OpenMV N6 + PAG7936
/sentry        Nucleo N657 + STEVAL-66GYMAI1 + moteus-C1 + GL35
/downloads     Chromium downloads
/tinygrad      upstream + venv (`gpu`)
```

```
nixos-rebuild switch --flake /etc/nixos#blackwell
n6 check
n6 load ELF
gpu
grok
```

## Topology

```
power
  │
  ▼
sway  raptors.jpeg
  │
  ▼
foot
  grok   gpu   n6   hw
        │
        │  gcc gdb arm-none-eabi-gcc
        │  OpenOCD n6 CUDA
        │
        ├─ /drone    OpenMV N6     MiniE
        └─ /sentry   Nucleo N657   CN10
```

Plug a board. `n6 load ELF` uses that ST-LINK.

Vendor CLIs are Nix packages: `stprogr` (CubeProgrammer 2.23.0), `stedgeai` (Edge AI Core 4.0.1).
ST zips live on Ventoy `st/` (UUID FBDE-EAD7). No `/opt/st`.

## Layout

| File | What |
|---|---|
| `flake.nix` | `nixosConfigurations.blackwell` (GitHub `marcelsachs/base`) |
| `configuration.nix` | NVIDIA, udev, sway, packages |
| `users.nix` | seat sachs HOME=/sachs. root HOME=/root SSH |
| `tools.nix` | gcc, arm-gcc, OpenOCD n6, n6, hw, gpu, st* |
| `n6/` | n6, hw, boards, gdb-dashboard |
| `st/` | CubeProgrammer + Edge AI Nix packages |
| `grok.toml` | grok config |
| `sandbox.toml` | grok sandbox |
| `install.sh` | wipe nvme0n1, add Ventoy `st/` blobs, nixos-install |
| `bootstrap.sh` | clone drone/sentry + LFS |
