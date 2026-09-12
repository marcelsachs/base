{ lib, config, ... }:
{
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  services.tailscale.authKeyFile = lib.mkIf config.stick.enable "/var/lib/secrets/tailscale.key";
}
