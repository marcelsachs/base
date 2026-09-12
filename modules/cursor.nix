{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage ../packages/cursor.nix { })
    pkgs.cursor-cli
  ];
}
