{
  config,
  pkgs,
  ...
}:
let
  stprogr = pkgs.callPackage ./st/progr.nix { };
  stedgeai = pkgs.callPackage ./st/edgeai.nix { };
in
{
  networking.hostName = "blackwell";
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "neoqwertz";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 8;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = [
    "nouveau"
    "simpledrm"
  ];
  boot.kernelParams = [ "nowatchdog" ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_uvm"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;
  services.xserver.enable = false;
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;
  systemd.network.enable = true;
  systemd.network.networks."20-wired" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  services.openssh.settings.PrintMotd = false;
  services.openssh.settings.PrintLastLog = false;

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


  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374?|375?", TAG+="uaccess", MODE="0666", SYMLINK+="stlink/$attr{serial}"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374?|375?", SYMLINK+="tty-stlink/$attr{serial}"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", TAG+="uaccess", MODE="0666", SYMLINK+="stm32dfu"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", TAG+="uaccess", SYMLINK+="tty-stm32/$attr{serial}"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-card"
  '';

  services.fstrim.enable = true;
  hardware.bluetooth.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraOptions = [ "--unsupported-gpu" ];
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_DRM_DEVICES=/dev/dri/nvidia-card
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NIXOS_OZONE_WL=1
      export LD_LIBRARY_PATH=/run/opengl-driver/lib
    '';
  };
  programs.foot = {
    enable = true;
    settings.main.font = "IBM Plex Mono:size=10";
  };
  fonts.packages = [ pkgs.ibm-plex ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "IBM Plex Sans" ];
    serif = [ "IBM Plex Serif" ];
    monospace = [ "IBM Plex Mono" ];
  };
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=IBM Plex Sans 10
  '';
  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=IBM Plex Sans 10
  '';
  environment.etc."xdg/waybar/config.jsonc".source = ./waybar/config.jsonc;
  environment.etc."xdg/waybar/style.css".source = ./waybar/style.css;
  environment.etc."xdg/waybar/tailscale" = {
    source = ./waybar/tailscale;
    mode = "0755";
  };
  environment.etc."xdg/waybar/gpu" = {
    source = ./waybar/gpu;
    mode = "0755";
  };

  environment.etc."greetd/session" = {
    source = pkgs.writeShellScript "greetd-session" ''
      set -euo pipefail
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_DRM_DEVICES=/dev/dri/nvidia-card
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NIXOS_OZONE_WL=1
      export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      exec ${config.programs.sway.package}/bin/sway
    '';
    mode = "0755";
  };
  environment.etc."sway/raptors.jpeg".source = ./raptors.jpeg;

  services.greetd = {
    enable = true;
    useTextGreeter = false;
    settings = {
      initial_session = {
        command = "/etc/greetd/session";
        user = "sachs";
      };
      default_session = {
        command = "/etc/greetd/session";
        user = "sachs";
      };
    };
  };
  systemd.services.greetd.restartIfChanged = false;
  systemd.services.greetd.stopIfChanged = false;
  services.speechd.enable = false;
  services.xserver.xkb.layout = "de";
  services.xserver.xkb.variant = "neo_qwertz";
  environment.etc."sway/config.d/blackwell.conf".text = ''
    set $term foot
    font pango:IBM Plex Sans 10
    output HDMI-A-1 pos 0 0
    output DP-1 mode 1920x1080@144Hz pos 1920 0
    output * bg /etc/sway/raptors.jpeg fill
    bar bar-0 {
        swaybar_command waybar
        position bottom
        mode dock
    }
    input type:keyboard {
        xkb_layout de
        xkb_variant neo_qwertz
    }
    exec foot
  '';

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    zstd
    stdenv.cc.cc
    libxml2
    openssl
    libusb1
    systemd
    glib
    krb5
    brotli
    libxkbcommon
    libx11
    libxcb
    libGL
    fontconfig
    freetype
  ];

  systemd.tmpfiles.rules = [
    "d /downloads 0775 sachs wheel -"
    "z /etc/nixos 0775 sachs wheel -"
  ];

  # systemd Q /home
  environment.etc."tmpfiles.d/home.conf".text = pkgs.lib.mkForce ''
    q /srv 0755 - - -
  '';

  programs.chromium.enable = true;
  programs.chromium.extraOpts = {
    DownloadDirectory = "/downloads";
    DefaultDownloadDirectory = "/downloads";
    PromptForDownloadLocation = false;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.direnv.enableBashIntegration = true;
  programs.direnv.settings = {
    global.hide_env_diff = true;
  };

  programs.ssh.knownHosts.github = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      init.defaultBranch = "master";
      core.editor = "vim";
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };

  environment.etc.vimrc.text = ''
    colorscheme lunaperche
    set background=dark
    set expandtab
    set hlsearch
    set ignorecase
    set incsearch
    set shiftwidth=4
    set tabstop=4
    syntax on

    set clipboard=unnamedplus
    autocmd TextYankPost * if v:event.operator ==# 'y'
          \ | call system("wl-copy", join(v:event.regcontents, "\n"))
          \ | endif
  '';

  environment.variables.EDITOR = "vim";
  environment.variables.BROWSER = "chromium";
  environment.variables.DL = "/downloads";
  environment.variables.XDG_DOWNLOAD_DIR = "/downloads";
  xdg.mime.defaultApplications = {
    "text/html" = "chromium-browser.desktop";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
  };
  environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";
  programs.bash.completion.enable = true;
  environment.interactiveShellInit = ''
    PS1='\[\033[1;38;5;39m\]\w \[\033[1;38;5;226m\]$ \[\033[0m\]'
    HISTSIZE=50000
    HISTFILESIZE=100000
    HISTCONTROL=ignoreboth:erasedups
    shopt -s histappend
    PROMPT_COMMAND="history -a; history -n''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    alias r=ranger
  '';

  environment.systemPackages = with pkgs; [
    stprogr
    stedgeai
    vim
    gh
    ranger
    curl
    wget
    pciutils
    usbutils
    file
    poppler-utils
    ripgrep
    wl-clipboard
    nvtopPackages.full
    waybar
    bubblewrap
    chromium
    (python3.withPackages (
      ps: with ps; [
        pip
        setuptools
        wheel
      ]
    ))
  ];

  system.stateVersion = "26.05";
}
