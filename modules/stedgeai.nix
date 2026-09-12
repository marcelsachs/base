{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.stick.enable {
    environment.systemPackages = [
      (pkgs.callPackage ../packages/stedgeai.nix { })
    ];
  };
}
