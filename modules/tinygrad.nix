{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage ../packages/tinygrad.nix { src = inputs.tinygrad; })
  ];
}
