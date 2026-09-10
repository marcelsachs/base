{
  config,
  pkgs,
  lib,
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
  boot.loader.timeout = 3;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "nowatchdog" ];

  hardware.graphics.enable = true;
  # The AMD iGPU drives the monitors. The NVIDIA card is compute only: no KMS,
  # so wlroots never sees it. videoDrivers is what activates hardware.nvidia.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = false;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  nixpkgs.config.allowUnfree = true;

  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;

  # SSH: keys only, reachable only over the tailnet. Root is reached via sudo.
  services.openssh.enable = true;
  services.openssh.openFirewall = false;
  services.openssh.settings.PasswordAuthentication = false;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  # One password for console and rescue shell; the hash lives outside the repo.
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

  services.fstrim.enable = true;
  hardware.bluetooth.enable = true;

  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;
  # sway nags whenever the nvidia module is loaded, regardless of which GPU renders.
  programs.sway.extraOptions = [ "--unsupported-gpu" ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.foot = {
    enable = true;
    settings.main.font = "monospace:size=10";
  };
  fonts.packages = [ pkgs.ibm-plex ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "IBM Plex Sans" ];
    serif = [ "IBM Plex Serif" ];
    monospace = [ "IBM Plex Mono" ];
  };
  environment.etc."sway/status" = {
    source = ./sway/status;
    mode = "0755";
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = lib.getExe config.programs.sway.package;
      user = "sachs";
    };
  };
  services.speechd.enable = false;
  environment.etc."sway/config.d/blackwell.conf".text = ''
    set $term foot
    font pango:sans 10
    output "Dell Inc. SE2417HGX 0x30594A42" pos 0 0
    output "Acer Technologies Acer XF240H 0x6040511D" mode 1920x1080@144Hz pos 1920 0
    output * bg ~/.config/sway/bg fill
    bar bar-0 {
        position bottom
        status_command /etc/sway/status
        font pango:monospace 10
        colors {
            background #000000
            statusline #ffffff
            focused_workspace #285577 #285577 #ffffff
            inactive_workspace #222222 #222222 #888888
        }
    }
    input type:keyboard {
        xkb_layout de
        xkb_variant neo_qwertz
    }
    input type:tablet_tool {
        map_to_output "Acer Technologies Acer XF240H 0x6040511D"
    }
  '';

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

    autocmd TextYankPost * if v:event.operator ==# 'y'
          \ | call system("wl-copy", join(v:event.regcontents, "\n"))
          \ | endif
  '';

  environment.variables.EDITOR = "vim";
  environment.variables.BROWSER = "chromium";
  environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";
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
    pciutils
    usbutils
    file
    poppler-utils
    ripgrep
    wl-clipboard
    nvtopPackages.full
    chromium
    xournalpp
    python3
    grok-build
    cursor-cli
  ];

  system.stateVersion = "26.05";
}
