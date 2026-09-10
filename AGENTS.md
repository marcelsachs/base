# base

Determinate Nix. Rebuild:

    nixos-rebuild switch --flake /etc/nixos#blackwell

Boot is Sway. Seat `sachs`. HOME=/sachs. Root is rebuild and SSH.

| | |
|---|---|
| `grok` | this agent. charter `/etc/nixos/AGENTS.md`. `GROK_HOME=/sachs/.grok` |

| Path | What |
|---|---|
| `/etc/nixos` | this flake |
| `/downloads` | Chromium downloads |
| `/tinygrad` | upstream + `.venv` |

Do not `nix-env`. C, bash, Python stdlib.

`/tmp` is throwaway. Append to `traces.md` in the repo you touched.
