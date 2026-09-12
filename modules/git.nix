{
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user.name = "marcelsachs";
      user.email = "sachsmarcel@proton.me";
      init.defaultBranch = "master";
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gist.github.com:".insteadOf = "https://gist.github.com/";
      safe.directory = [
        "/base"
        "/docs"
        "/drone"
        "/sentry"
        "/lab"
        "/etc/nixos"
      ];
    };
  };
}
