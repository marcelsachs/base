{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage ../packages/bambu-studio.nix { })
  ];
  # Printer SSDP announcements (LAN discovery).
  networking.firewall.allowedUDPPorts = [
    1990
    2021
  ];
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -m pkttype --pkt-type multicast -j nixos-fw-accept
  '';
}
