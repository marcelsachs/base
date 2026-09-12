{ pkgs, ... }:
{
  fonts.packages = [ pkgs.ibm-plex ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "IBM Plex Sans" ];
    serif = [ "IBM Plex Serif" ];
    monospace = [ "IBM Plex Mono" ];
  };
}
