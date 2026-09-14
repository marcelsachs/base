{
  lib,
  fetchurl,
  appimageTools,
  cacert,
  glib-networking,
  webkitgtk_4_1,
  gst_all_1,
  curl,
  glib,
  libsecret,
}:
let
  pname = "bambu-studio";
  version = "02.08.02.61";
  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-20260820225108.AppImage";
    hash = "sha256-1QGxA/rFQkUT7A6Na8FF+zBxneLH2U1zINcjdAyBp/0=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  # GUI must outlive the launching terminal (bwrap --die-with-parent).
  dieWithParent = false;

  extraPkgs = pkgs: [
    cacert
    curl
    glib
    glib-networking
    webkitgtk_4_1
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    libsecret
  ];

  # WebKit login/device views blank without DMABUF disabled; GIO/SSL needed
  # for the network plugin. Force Mesa so the RTX compute GPU is not used.
  profile = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export CURL_CA_BUNDLE=$SSL_CERT_FILE
    export GIO_MODULE_DIR=${glib-networking}/lib/gio/modules/
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
    export GDK_BACKEND=x11
    export __GLX_VENDOR_LIBRARY_NAME=mesa
  '';

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/BambuStudio.desktop \
      $out/share/applications/bambu-studio.desktop
    substituteInPlace $out/share/applications/bambu-studio.desktop \
      --replace-fail 'Exec=AppRun %U' 'Exec=bambu-studio %U'
    install -m 444 -D ${appimageContents}/BambuStudio.png \
      $out/share/pixmaps/BambuStudio.png
    install -m 444 -D ${appimageContents}/BambuStudio.png \
      $out/share/icons/hicolor/128x128/apps/BambuStudio.png
  '';

  meta = {
    description = "PC software for Bambu Lab 3D printers";
    homepage = "https://bambulab.com/en/download/studio";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
  };
}
