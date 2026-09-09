{
  lib,
  stdenv,
  requireFile,
  unzip,
  python3,
  makeWrapper,
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
      Mount Ventoy UUID FBDE-EAD7, then:
      nix-prefetch-url file:///mnt/st/SetupSTM32CubeProgrammer_linux_64.zip
    '';
  };

  nativeBuildInputs = [
    unzip
    python3
    makeWrapper
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    unzip -q "$src" SetupSTM32CubeProgrammer-${version}.exe
    python3 ${./izpack-unpack.py} SetupSTM32CubeProgrammer-${version}.exe ${./progr-pack.json} "$out"
    mkdir -p "$out/bin"
    makeWrapper "$out/bin/STM32_Programmer_CLI" "$out/bin/stprogr" \
      --set STM32_PRG_PATH "$out/bin" \
      --prefix LD_LIBRARY_PATH : "$out/lib"
    chmod +x "$out/bin/STM32_Programmer_CLI"
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
