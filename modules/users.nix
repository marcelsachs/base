{ lib, config, ... }:
{
  users.mutableUsers = false;
  users.users.root = {
    hashedPasswordFile = lib.mkIf config.stick.enable "/var/lib/secrets/password.hash";
    # password: root
    hashedPassword =
      lib.mkIf (!config.stick.enable)
        "$6$8J13ATb1cObDJmhh$Xa9xtL2N2Ly16DeGwwbASkqGXTrs//qoeMZR637X4dZR9WxmGO/pxmXrl/ygPTPMikqlFlpjqNOzorZC6hN3r0";
  };
  users.users.sachs = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
      "dialout"
      "render"
    ];
    hashedPasswordFile = lib.mkIf config.stick.enable "/var/lib/secrets/password.hash";
    hashedPassword =
      lib.mkIf (!config.stick.enable)
        "$6$8J13ATb1cObDJmhh$Xa9xtL2N2Ly16DeGwwbASkqGXTrs//qoeMZR637X4dZR9WxmGO/pxmXrl/ygPTPMikqlFlpjqNOzorZC6hN3r0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3mQnGAwa871FKI/aRUyHXGUKyk9h2SyNI7ASy1t7Q0 sachs@helios"
    ];
  };
}
