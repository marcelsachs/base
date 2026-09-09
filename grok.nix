{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  # Bump version + hash, then nixos-rebuild, to update the store copy.
  # `grok update` also writes ~/.grok/bin, which is first on PATH.
  pname = "grok-cli";
  version = "1.0.13";
  src = fetchurl {
    url = "https://x.ai/cli/grok-${version}-linux-x86_64";
    hash = "sha256-7feVIVgbtea5Wr74SEkaanQuhg2j4jfr6GooDTDc5ME=";
  };
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/grok"
    ln -s grok "$out/bin/agent"
    runHook postInstall
  '';
  meta = {
    description = "xAI Grok CLI";
    homepage = "https://x.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "grok";
  };
}
