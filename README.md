# base

NixOS. Hostname `blackwell`. Seat `sachs` HOME=/sachs. Root is rebuild and SSH.

    nixos-rebuild switch --flake /etc/nixos#blackwell

```
/etc/nixos     this flake
/drone         OpenMV N6 + PAG7936
/sentry        Nucleo N657 + STEVAL-66GYMAI1
/downloads     Chromium
/tinygrad      tinygrad + CUDA
```

`n6 load ELF` uses the plugged ST-LINK.
`stprogr` CubeProgrammer 2.23.0. `stedgeai` Edge AI Core 4.0.1.
ST blobs: Ventoy `st/` UUID FBDE-EAD7. `install.sh` adds them to the store.

`docs/install.md`
