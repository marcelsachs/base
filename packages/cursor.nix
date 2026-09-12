{
  lib,
  fetchurl,
  appimageTools,
  makeWrapper,
}:
let
  pname = "cursor";
  version = "3.20.10";
  src = fetchurl {
    url = "https://downloads.cursor.com/production/d6f462cdd0a6a6d1cff570daf980e671d0a63ded/linux/x64/Cursor-3.20.10-x86_64.AppImage";
    hash = "sha256-zCY0PNenWzX5U6nXF7okUFz+GzV3E7vKV69llfdWhFA=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  nativeBuildInputs = [ makeWrapper ];
  # VS Code/Cursor detaches from the launching terminal.
  dieWithParent = false;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/usr/share/applications/cursor.desktop \
      $out/share/applications/cursor.desktop
    substituteInPlace $out/share/applications/cursor.desktop \
      --replace-fail 'Exec=/usr/share/cursor/cursor' 'Exec=cursor'
    mkdir -p $out/share/pixmaps $out/share/icons
    cp -r ${appimageContents}/usr/share/icons/hicolor $out/share/icons/
    cp ${appimageContents}/usr/share/pixmaps/co.anysphere.cursor.png $out/share/pixmaps/
    wrapProgram "$out/bin/${pname}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
  '';

  meta = {
    description = "AI-powered code editor built on vscode";
    homepage = "https://cursor.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}
