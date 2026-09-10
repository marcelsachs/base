{
  lib,
  stdenv,
  requireFile,
  buildFHSEnv,
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
    stdenv.cc.cc
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
  unwrapped = stdenv.mkDerivation rec {
    pname = "stedgeai-unwrapped";
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

    nativeBuildInputs = [ stdenv.cc.bintools ];
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
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
      runHook postInstall
    '';
  };
in
buildFHSEnv {
  pname = "stedgeai";
  version = "4.0.1";
  targetPkgs = _: libs;
  extraInstallCommands = ''
    ln -s ${unwrapped}/4.0 $out/4.0
  '';
  profile = ''
    export ST_EDGEAI=${unwrapped}/4.0
  '';
  runScript = "${unwrapped}/4.0/Utilities/linux/stedgeai";
  meta = {
    description = "ST Edge AI Core CLI (STM32 MCU + Neural-ART)";
    homepage = "https://www.st.com/en/development-tools/stedgeai-core.html";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stedgeai";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
