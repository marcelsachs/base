{
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  services.tailscale.authKeyFile = "/var/lib/secrets/tailscale.key";
}
