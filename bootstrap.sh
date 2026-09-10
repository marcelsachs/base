#!/usr/bin/env bash
# After first boot. Desks later.
set -euo pipefail
[[ $(id -u) -ne 0 ]] || { echo "run as the seat user, not root" >&2; exit 1; }
echo "base."
