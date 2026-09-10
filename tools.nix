{
  pkgs,
  ...
}:
let
  stprogr = pkgs.callPackage ./st/progr.nix { };
  stedgeai = pkgs.callPackage ./st/edgeai.nix { };
in
{
  environment.systemPackages = [
    stprogr
    stedgeai
  ];
}
