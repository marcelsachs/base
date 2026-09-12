{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.gh ];
  programs.git.config = {
    credential."https://github.com".helper = [
      ""
      "!${pkgs.gh}/bin/gh auth git-credential"
    ];
    credential."https://gist.github.com".helper = [
      ""
      "!${pkgs.gh}/bin/gh auth git-credential"
    ];
  };
}
