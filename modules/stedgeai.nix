{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage "${inputs.stm32n6}/stedgeai.nix" { })
  ];
}
