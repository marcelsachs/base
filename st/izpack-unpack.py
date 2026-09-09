#!/usr/bin/env python3
# Unpack STM32CubeProgrammer IzPack packs. File list is progr-pack.json.
import gzip
import io
import json
import os
import sys
import zipfile

exe, meta, dest = sys.argv[1], sys.argv[2], sys.argv[3]
rows = json.load(open(meta))
raw = open(exe, "rb").read()
z = zipfile.ZipFile(io.BytesIO(raw[raw.find(b"PK\x03\x04") :]))
blobs = {}
for r in rows:
    n = r["pack"]
    if n not in blobs:
        blobs[n] = z.read("resources/packs/pack-" + n)

os.makedirs(dest, exist_ok=True)
for r in rows:
    dst = r["dst"].replace("$INSTALL_PATH", dest)
    if r["dir"]:
        os.makedirs(dst, exist_ok=True)
        continue
    cond = r.get("cond")
    if cond not in (None, "izpack.linuxinstall", "!izpack.windowsinstall"):
        continue
    piece = blobs[r["pack"]][r["off"] : r["off"] + r["psz"]]
    if piece[:2] == b"\x1f\x8b":
        data = gzip.decompress(piece)
    elif len(piece) == r["len"]:
        data = piece
    else:
        continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, "wb") as f:
        f.write(data)
    base = os.path.basename(dst)
    if base.endswith(".sh") or base.endswith("_CLI") or base.endswith("Launcher"):
        os.chmod(dst, 0o755)
