{
  lib,
  stdenv,
  requireFile,
  writeShellScript,
  autoPatchelfHook,
  unzip,
  jdk_headless,
  libusb1,
  zlib,
  zstd,
  glib,
  krb5,
  brotli,
}:

let
  # After unpacking, IzPack runs "/bin/chmod a+x SCRIPT" and then SCRIPT (#!/bin/bash) for each
  # post-install script; neither path exists in the sandbox. This stands in for chmod: it points
  # the script's shebang at our bash first, so the script (jre copy, chmod +x on the CLIs) runs.
  chmodStub = writeShellScript "chmod" ''
    sed -i '1s|^#!/bin/bash$|#!${stdenv.shell}|' "$2" && exec chmod "$@"
  '';
in
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
    autoPatchelfHook
    unzip
    jdk_headless
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    libusb1
    zlib
    zstd
    glib
    krb5
    brotli
  ];
  # The bundled Qt GUI libraries and libjlinkarm want X11, GL and more that no CLI reaches.
  autoPatchelfIgnoreMissingDeps = true;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    unzip -q "$src" SetupSTM32CubeProgrammer-${version}.exe
    # FileExecutor holds "/bin/chmod" as one class constant; swap it for a same-length relative
    # path to the stub and shadow the class by putting the copy first on the classpath.
    # jar, not unzip: the .exe has a Windows stub in front of the zip, which unzip treats as an error.
    mkdir -p shadow cc
    (cd shadow && jar xf ../SetupSTM32CubeProgrammer-${version}.exe com/izforge/izpack/util/FileExecutor.class)
    sed -i 's|/bin/chmod|./cc/chmod|' shadow/com/izforge/izpack/util/FileExecutor.class
    ln -s ${chmodStub} cc/chmod
    # The IzPack installer copies ./jre next to itself into bin/jre; a stub keeps it going.
    mkdir -p jre/bin && touch jre/bin/java
    # Unattended console install; -options-system takes every variable from -D properties.
    HOME=$TMPDIR java -Djava.awt.headless=true -DINSTALL_PATH="$out" \
      -cp shadow:SetupSTM32CubeProgrammer-${version}.exe \
      com.izforge.izpack.installer.bootstrap.Installer -options-system
    cd "$out"
    rm -rf bin/jre uninstaller util .installationinformation
    # Only the CLIs and what they load. Out: the GUI with its Java launcher, Qt GUI libraries and
    # platform plugins; TrustedPackageCreator (Qt Widgets, wants GL and X11); the C++ API; SVD
    # files; J-Link; the HSM smartcard stack (wants libpcsclite); imgtool; udev rules and Windows
    # drivers; flash loaders, external loaders and open bootloaders for devices other than the N6.
    rm -rf SVD api Drivers \
      bin/STM32CubeProgrammer* bin/STM32_Programmer.sh bin/platforms bin/translations_files \
      lib/libQt6{Gui,Widgets,OpenGL,XcbQpa,DBus}.so.6 lib/libxcb-cursor.so.0 \
      bin/STM32TrustedPackageCreator* bin/TPC_*_Data_Base lib/libPreparation.so \
      lib/libCubeProgrammer_API.so* lib/libFileManager.so.1 lib/libssl.so.3 \
      lib/libjlinkarm.so share/doc/License_Segger_JLink.txt \
      bin/libstp11_SAM.so* lib/libstp11_SAM.so* lib/libxerces-c-3.3.so lib/libicu*.so.52 bin/HSM \
      bin/Utilities/Linux/imgtool bin/Utilities/Linux/LICENSE.ImgTool \
      bin/FlashLoader bin/OBL bin/STM32WLScripts
    find bin/ExternalLoader -type f ! -name '*STM32N6*' -delete
    chmod +x bin/*_CLI
    # Qt looks for Data_Base and friends next to /proc/self/exe, so the CLIs must run as themselves,
    # not through ld.so; autoPatchelf gives them and the bundled libraries our loader and paths.
    ln -s STM32_Programmer_CLI bin/stprogr
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
