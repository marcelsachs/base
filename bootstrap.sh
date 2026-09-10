#!/usr/bin/env bash
# After first boot. Clones drone/sentry + git lfs pull.
# tinygrad: clone into /tinygrad.
set -euo pipefail
[[ $(id -u) -ne 0 ]] || { echo "run as the seat user, not root" >&2; exit 1; }

clone_desk() {
  local dest=$1 url=$2
  if [[ -d $dest/.git ]]; then
    echo "$dest already cloned"
    git -C "$dest" pull --ff-only
    git -C "$dest" lfs pull
    return
  fi
  if [[ -n $(ls -A "$dest" 2>/dev/null) ]]; then
    echo "error: $dest is not empty and not a git repo" >&2
    exit 1
  fi
  git clone "$url" "$dest"
  git -C "$dest" lfs pull
}

clone_desk /drone  git@github.com:marcelsachs/drone.git
clone_desk /sentry git@github.com:marcelsachs/sentry.git

chmod 2775 /drone /sentry
echo "desks cloned."
