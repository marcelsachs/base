{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.chromium ];
  environment.variables.BROWSER = "chromium";
}
