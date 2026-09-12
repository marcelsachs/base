{
  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = "/var/lib/secrets/password.hash";
  users.users.sachs = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
      "dialout"
      "render"
    ];
    hashedPasswordFile = "/var/lib/secrets/password.hash";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3mQnGAwa871FKI/aRUyHXGUKyk9h2SyNI7ASy1t7Q0 sachs@helios"
    ];
  };
}
