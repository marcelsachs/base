{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ranger ];
  environment.interactiveShellInit = ''
    alias r=ranger
  '';
}
