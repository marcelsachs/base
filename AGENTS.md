# base

STM32N6 workstation. Determinate Nix. Rebuild:

    nixos-rebuild switch --flake /etc/nixos#blackwell

Boot is Sway. Seat `sachs`. HOME=/sachs. Root is rebuild and SSH.

| | |
|---|---|
| `grok` | this agent. charter `/etc/nixos/AGENTS.md`. `GROK_HOME=/sachs/.grok` |
| `n6` | STM32N6 load/debug. Plug USB, `n6 load ELF` |

| Path | What |
|---|---|
| `/etc/nixos` | machine. gcc, arm-gcc, gdb, OpenOCD, n6, stprogr, stedgeai, CUDA |
| `/drone` | OpenMV N6 + PAG7936 |
| `/sentry` | Nucleo N657 + STEVAL-66GYMAI1 |
| `/downloads` | Chromium downloads |
| `/tinygrad` | upstream + `.venv` |

Do not `nix-env`. Compilers and `n6` are on PATH. C, bash, Python stdlib. No Rust.

OpenOCD + gdb load AXISRAM.
`stprogr` CubeProgrammer 2.23.0. `stedgeai` Edge AI Core 4.0.1, STM32 MCU + Neural-ART.
ST zips on Ventoy `st/` (UUID FBDE-EAD7). `install.sh` adds them to the target store.
After GC: mount the stick, `nix store add --mode flat --hash-algo sha256 /mnt/st/FILE`.

Two USB ports, two ST-LINKs. The plugged probe is the board. `-b openmv` / `-b nucleo` if both are in.

Never reset a running AXISRAM image. Vector table `0x34000400`. Cortex-M55 is AP1.
HOTPLUG. Never call openocd except through `n6`. No Cube HAL. Secure aliases (RM0486 3.5.1).

`/tmp` is throwaway. Append to `traces.md` in the repo you touched.

Comments, READMEs, traces: the fact, the command, the pin, the register.
What bricks the board or the image.
