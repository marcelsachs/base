#!/usr/bin/env bash
set -euo pipefail
h=${HOME:-/sachs}
j=$(curl -fsSL "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable")
u=${j#*\"downloadUrl\":\"}; u=${u%%\"*}
v=${j#*\"version\":\"}; v=${v%%\"*}
[[ $u == https://* ]]
d=$h/.local/share/cursor
mkdir -p "$d" "$h/.local/bin"
if [[ -n ${v-} && -x $d/cursor.AppImage && -f $d/version && $(<"$d/version") == "$v" ]]; then
  :
else
  curl -fL -o "$d/cursor.AppImage.part" "$u"
  chmod +x "$d/cursor.AppImage.part"
  mv "$d/cursor.AppImage.part" "$d/cursor.AppImage"
  printf '%s\n' "$v" >"$d/version"
fi
printf '#!/bin/sh\nexec "%s" --no-sandbox "$@"\n' "$d/cursor.AppImage" >"$h/.local/bin/cursor"
chmod +x "$h/.local/bin/cursor"
