# Experiment: stedgeai without buildFHSEnv. Test on the machine:
#   nix build /etc/nixos#stedgeai-patchelf && result/bin/stedgeai --version
#   nix log /etc/nixos#stedgeai-patchelf | grep -i "missing\|warn"
# Then run one real `stedgeai generate` from n6lab. Works: this replaces
# edgeai.nix. Fails: delete this file and its line in flake.nix.
{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  zstd,
  bzip2,
  xz,
  libxkbcommon,
  libX11,
  libxcb,
  libxcb-wm,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  dbus,
  libGL,
  freetype,
  fontconfig,
  libpng,
  systemd,
  brotli,
  libxcb-util,
}:
let
  libs = [
    stdenv.cc.cc.lib
    zlib
    zstd
    bzip2
    xz
    libxkbcommon
    libX11
    libxcb
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    dbus
    libGL
    freetype
    fontconfig
    libpng
    systemd
    brotli
    libxcb-util
  ];
in
stdenv.mkDerivation rec {
  pname = "stedgeai";
  version = "4.0.1";

  src = requireFile {
    name = "stedgeai-linux-offline";
    hash = "sha256-5TQEIqRndPYtM+LYyMeuNgF4Q4D+oMz5f5ydpW5jd1M=";
    url = "https://www.st.com/en/development-tools/stedgeai-core.html";
    message = "ST Edge AI Core ${version} offline installer is not in the Nix store; install.sh adds it from the stick.";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = libs;
  # Report missing libraries in the build log instead of failing; that is the experiment.
  autoPatchelfIgnoreMissingDeps = true;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    export HOME=$TMPDIR
    export QT_QPA_PLATFORM=offscreen
    export LD_LIBRARY_PATH="${lib.makeLibraryPath libs}"
    cp $src installer
    chmod 755 installer
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} installer
    mkdir -p $out
    ./installer \
      --accept-licenses --accept-messages --confirm-command \
      --auto-answer installationErrorWithCancel=Ignore \
      --root $out \
      install stedgeai0400.stm32mcu
    rm -rf "$out"/MaintenanceTool*
    makeWrapper $out/4.0/Utilities/linux/stedgeai $out/bin/stedgeai --set ST_EDGEAI $out/4.0
    runHook postInstall
  '';

  meta = {
    description = "ST Edge AI Core CLI, patched ELF instead of an FHS sandbox";
    homepage = "https://www.st.com/en/development-tools/stedgeai-core.html";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stedgeai";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
