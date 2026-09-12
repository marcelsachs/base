{
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user.name = "marcelsachs";
      user.email = "sachsmarcel@proton.me";
      init.defaultBranch = "master";
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };
}
