{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.stick.enable {
    environment.systemPackages = [
      (pkgs.callPackage ../packages/stprogr.nix { })
    ];
    # NUCLEO-N657X0-Q
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3754", ATTR{serial}=="003300243234510337333934", MODE="0660", GROUP="dialout"
    '';
  };
}
