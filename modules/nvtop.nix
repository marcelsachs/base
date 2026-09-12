{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.nvtopPackages.full ];
}
