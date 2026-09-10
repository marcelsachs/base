{
  lib,
  stdenv,
  requireFile,
  unzip,
  python3,
  makeWrapper,
  libusb1,
  zlib,
  zstd,
  glib,
  krb5,
  brotli,
}:

stdenv.mkDerivation rec {
  pname = "stprogr";
  version = "2.23.0";

  src = requireFile {
    name = "SetupSTM32CubeProgrammer_linux_64.zip";
    hash = "sha256-ap5gpaBIxF6zJB+btmvcLmy9ARn7LkJWjcBZ/GFnRCo=";
    url = "https://www.st.com/en/development-tools/stm32cubeprog.html";
    message = ''
      ST CubeProgrammer ${version} zip is not in the Nix store.
      Mount Ventoy, then:
      nix-prefetch-url file:///usb/st/SetupSTM32CubeProgrammer_linux_64.zip
    '';
  };

  nativeBuildInputs = [
    unzip
    python3
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc
    libusb1
    zlib
    zstd
    glib
    krb5
    brotli
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    unzip -q "$src" SetupSTM32CubeProgrammer-${version}.exe
    python3 ${./izpack-unpack.py} SetupSTM32CubeProgrammer-${version}.exe ${./progr-pack.json} "$out"
    mkdir -p "$out/bin"
    chmod +x "$out/bin/STM32_Programmer_CLI"
    makeWrapper ${stdenv.cc.bintools.dynamicLinker} "$out/bin/stprogr" \
      --argv0 STM32_Programmer_CLI \
      --add-flags "$out/bin/STM32_Programmer_CLI" \
      --set STM32_PRG_PATH "$out/bin" \
      --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
    runHook postInstall
  '';

  meta = {
    description = "STM32CubeProgrammer CLI";
    homepage = "https://www.st.com/en/development-tools/stm32cubeprog.html";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stprogr";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
