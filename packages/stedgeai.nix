{
  lib,
  stdenv,
  requireFile,
  writeText,
  autoPatchelfHook,
  makeWrapper,
  python3,
  zlib,
  bzip2,
  xz,
}:

let
  # Unpack components of a Qt Installer Framework offline installer; later ones overwrite.
  qtifwUnpack = writeText "qtifw-unpack.py" ''
    import hashlib
    import io
    import mmap
    import os
    import struct
    import sys
    import zipfile

    blob, dest, components = sys.argv[1], sys.argv[2], sys.argv[3:]
    with open(blob, "rb") as f:
        raw = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    n = len(raw)
    resources, block_size, marker, cookie = struct.unpack_from("<QQQQ", raw, n - 32)
    assert (cookie, marker) == (0xC2630A1C99D668F8, 0x12023233), "not a QtIFW installer"
    base = n - block_size


    class Cursor:
        def __init__(self, pos):
            self.pos = pos

        def i64(self):
            (v,) = struct.unpack_from("<Q", raw, self.pos)
            self.pos += 8
            return v

        def name(self):
            length = self.i64()
            v = raw[self.pos : self.pos + length].decode()
            self.pos += length
            return v


    index = Cursor(base + struct.unpack_from("<Q", raw, n - 32 - 16 * (resources + 1) - 16)[0])
    collections = {}
    for _ in range(index.i64()):
        name, start, _length = index.name(), index.i64(), index.i64()
        collections[name] = start

    for component in components:
        cur = Cursor(base + collections[component])
        data = None
        for _ in range(cur.i64()):
            name, start, length = cur.name(), cur.i64(), cur.i64()
            piece = raw[base + start : base + start + length]
            if name.endswith(".sha1"):
                assert hashlib.sha1(data).hexdigest() == piece.decode().strip(), name
                continue
            data = piece
            with zipfile.ZipFile(io.BytesIO(data)) as z:
                for info in z.infolist():
                    path = os.path.join(dest, info.filename)
                    if info.is_dir():
                        os.makedirs(path, exist_ok=True)
                        continue
                    os.makedirs(os.path.dirname(path), exist_ok=True)
                    with open(path, "wb") as f:
                        f.write(z.read(info))
                    os.chmod(path, 0o755 if (info.external_attr >> 16) & 0o111 else 0o644)
  '';

  # ST's launchers were patched with an old patchelf that moved .note.gnu.property but left
  # its PT_NOTE header behind; patchelf >= 0.15 then refuses them ("cannot normalize PT_NOTE
  # segment"). Point each stale PT_NOTE header at the note section it lost.
  ptNoteFix = writeText "pt-note-fix.py" ''
    import os
    import struct
    import sys

    PT_NOTE, SHT_NOTE = 4, 7

    for path in sys.argv[1:]:
        os.chmod(path, 0o755)
        with open(path, "r+b") as f:
            d = bytearray(f.read())
            assert d[:5] == b"\x7fELF\x02", f"{path}: not a 64-bit ELF"
            e_phoff, e_shoff = struct.unpack_from("<QQ", d, 0x20)
            e_phentsize, e_phnum, e_shentsize, e_shnum = struct.unpack_from("<HHHH", d, 0x36)
            notes = {}
            for i in range(e_shnum):
                # Elf64_Shdr: name, type, flags, addr, offset, size, link, info, addralign, entsize
                sh = struct.unpack_from("<IIQQQQIIQQ", d, e_shoff + i * e_shentsize)
                if sh[1] == SHT_NOTE:
                    notes[sh[4]] = sh[5]
            # Elf64_Phdr: type, flags, offset, vaddr, paddr, filesz, memsz, align
            phdrs = {p: struct.unpack_from("<IIQQQQQQ", d, p) for p in (e_phoff + i * e_phentsize for i in range(e_phnum))}
            ranges = [(h[2], h[2] + h[5]) for h in phdrs.values() if h[0] == PT_NOTE]
            for p, (p_type, _, p_offset, _, _, p_filesz, _, _) in phdrs.items():
                if p_type != PT_NOTE or p_offset in notes:
                    continue
                lost = [o for o, z in notes.items() if z == p_filesz and not any(lo <= o < hi for lo, hi in ranges)]
                if len(lost) != 1:
                    sys.exit(f"{path}: PT_NOTE at {p_offset:#x} has no matching section, candidates {lost}")
                struct.pack_into("<QQQ", d, p + 8, lost[0], lost[0], lost[0])
                print(f"{path}: PT_NOTE {p_offset:#x} -> {lost[0]:#x}")
            f.seek(0)
            f.write(d)
  '';
in
stdenv.mkDerivation rec {
  pname = "stedgeai";
  version = "4.0.1";

  src = requireFile {
    name = "stedgeai-linux-offline";
    hash = "sha256-5TQEIqRndPYtM+LYyMeuNgF4Q4D+oMz5f5ydpW5jd1M=";
    url = "https://www.st.com/en/development-tools/stedgeai-core.html";
    message = ''
      ST Edge AI Core ${version} offline installer is not in the Nix store.
      Mount Ventoy, then:
      nix-prefetch-url file:///usb/st/stedgeai-linux-offline
    '';
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    python3
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    bzip2
    xz
  ];
  # ST ships an old ffmpeg/gtk/opencv library zoo that nothing reachable links.
  autoPatchelfIgnoreMissingDeps = true;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    # stm32mcu and its dependencies; core last, its headers win over stm32mculib's.
    python3 ${qtifwUnpack} $src $out/4.0 \
      stedgeai0400.stm32mculib stedgeai0400.stm32mcu stedgeai0400.stneuralart stedgeai0400.base stedgeai0400.core
    cd $out/4.0
    # Only the Linux tool and the N6 embedded side. Out: the Windows and macOS tools, the
    # documentation (stedgeai-dc.st.com has it), TensorFlow's C++ headers, test suites, the
    # library zoo nothing reachable links (a libpthread from another glibc among it), runtime
    # libraries and project files for other cores and for IAR and Keil.
    rm -rf Utilities/{windows,mac,macarm} Documentation Utilities/linux/lib/python3.9/test \
      Utilities/linux/lib/python3.9/site-packages/tensorflow/include
    find Utilities/linux/lib/python3.9/site-packages -type d \
      \( -name tests -o -path '*/onnx/test' -o -path '*/onnx/backend/test/data' \) -prune -exec rm -rf {} +
    find Utilities/linux/lib -maxdepth 1 -name '*.so*' ! -name 'libpython3.9.so*' ! -name 'libffi.so.6' \
      ! -name 'libssl.so.1.1' ! -name 'libcrypto.so.1.1' -delete
    # The launcher needs it by this name; it was a copy.
    ln -sf libpython3.9.so.1.0 Utilities/linux/lib/libpython3.9.so
    find Middlewares/ST/AI/Lib -mindepth 1 -maxdepth 2 ! -path '*/GCC' ! -path '*/GCC/ARMCortexM55' \
      -prune -exec rm -rf {} +
    find Projects -type d \( -name EWARM -o -name MDK-ARM \) -prune -exec rm -rf {} +
    # Symbol tables the dynamic linker never reads, 380 MB of them, most in TensorFlow. Not the two
    # launchers, ptNoteFix relies on their layout.
    while IFS= read -r -d "" f; do if isELF "$f"; then printf '%s\0' "$f"; fi; done \
      < <(find Utilities/linux -type f ! -name stedgeai ! -name uncompile -print0) \
      | xargs -0 -n1 -P "$NIX_BUILD_CORES" $STRIP --strip-unneeded
    python3 ${ptNoteFix} Utilities/linux/{stedgeai,uncompile}
    makeWrapper $out/4.0/Utilities/linux/stedgeai $out/bin/stedgeai --set ST_EDGEAI $out/4.0
    runHook postInstall
  '';

  meta = {
    description = "ST Edge AI Core CLI (STM32 MCU + Neural-ART)";
    homepage = "https://www.st.com/en/development-tools/stedgeai-core.html";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stedgeai";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
