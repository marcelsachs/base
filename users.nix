{ ... }:
{
  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3mQnGAwa871FKI/aRUyHXGUKyk9h2SyNI7ASy1t7Q0 sachs@helios"
    ];
  };
  users.users.sachs = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    home = "/sachs";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "input"
      "dialout"
      "render"
    ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3mQnGAwa871FKI/aRUyHXGUKyk9h2SyNI7ASy1t7Q0 sachs@helios"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  services.openssh.settings.PasswordAuthentication = false;
}
