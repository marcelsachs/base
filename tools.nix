{
  config,
  pkgs,
  ...
}:
let
  # nixpkgs OpenOCD 0.12.0 tarball has no stm32n6x.cfg.
  openocd-n6 = pkgs.openocd.overrideAttrs (old: {
    version = "0.12.0+n6";
    src = pkgs.fetchFromGitHub {
      owner = "openocd-org";
      repo = "openocd";
      rev = "1adf0eed5e53d32eb7b1feda814037154028694a";
      hash = "sha256-h0Wn6Z5x9ul9/BXZd7ubXlfIP8LQnGhKiWiiChJa6tQ=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      pkgs.autoconf
      pkgs.automake
      pkgs.libtool
      pkgs.which
    ];
    preConfigure = ''
      ./bootstrap nosubmodule
    '';
  });
  n6 = pkgs.writeShellScriptBin "n6" (builtins.readFile ./n6/n6);
  hw = pkgs.writeShellScriptBin "hw" (builtins.readFile ./n6/hw);
  stprogr = pkgs.callPackage ./st/progr.nix { };
  stedgeai = pkgs.callPackage ./st/edgeai.nix { };
in
{
  environment.etc."n6/boards".source = ./n6/boards;
  environment.etc."n6/gdb/n6.gdb".source = ./n6/gdb/n6.gdb;
  environment.etc."n6/gdb/dashboard.gdbinit".source = ./n6/gdb/dashboard.gdbinit;

  environment.systemPackages = [
    pkgs.bashInteractive
    pkgs.gcc
    pkgs.gdb
    pkgs.gnumake
    pkgs.gcc-arm-embedded
    openocd-n6
    pkgs.picocom
    pkgs.tmux
    pkgs.unzip
    n6
    hw
    stprogr
    stedgeai
  ];
}
