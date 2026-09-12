{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage "${inputs.stm32n6}/stprogr.nix" { })
  ];
  # NUCLEO-N657X0-Q: its on-board STLINK-V3EC, matched by serial so no other probe or DFU device is opened up.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3754", ATTR{serial}=="003300243234510337333934", MODE="0660", GROUP="dialout"
  '';
}
