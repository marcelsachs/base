{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  tinygrad = pkgs.callPackage ./tinygrad.nix { src = inputs.tinygrad; };
  # STM32N657 tooling. Both are requireFile: put ST's installers in the store first (see stm32n6).
  stprogr = pkgs.callPackage "${inputs.stm32n6}/stprogr.nix" { };
  stedgeai = pkgs.callPackage "${inputs.stm32n6}/stedgeai.nix" { };
  # swaybar status_command: one line per second. nvidia-smi only every 5th tick.
  status = pkgs.writeShellApplication {
    name = "status";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.iproute2
      config.hardware.nvidia.package.bin
      config.services.pipewire.wireplumber.package
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = ''
      for d in /sys/class/hwmon/hwmon*; do
        [[ -r $d/name && $(<"$d/name") == k10temp ]] && cpuhw=$d/temp1_input && break
      done
      tick=0 gpu='GPU: down' prev_idle=0 prev_total=0
      while :; do
        ips=$(ip -4 -o addr | awk '{split($4,a,"/"); if($2~/^en/)e=a[1]; else if($2~/^wl/)w=a[1]; else if($2=="tailscale0")t=a[1]}
          END{printf "E: %s | W: %s | T: %s", e?e:"down", w?w:"down", t?t:"down"}')
        read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
        total=$((user + nice + system + idle + iowait + irq + softirq + steal))
        busy=$((total - prev_total - (idle + iowait - prev_idle)))
        cpu=$((total > prev_total ? 100 * busy / (total - prev_total) : 0))
        prev_idle=$((idle + iowait)) prev_total=$total
        temp=''${cpuhw:+"CPU: $(($(<"$cpuhw") / 1000))°C "}
        if ((tick++ % 5 == 0)); then
          q=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
          gpu=''${q:+"GPU: ''${q%%,*}°C ''${q#*,}%"} gpu=''${gpu:-'GPU: down'}
        fi
        read -r load _ < /proc/loadavg
        mem=$(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{printf "%.1fG", (t-a)/1048576}' /proc/meminfo)
        vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "♪ %d%%%s", $2*100, $3=="[MUTED]" ? " muted" : ""}')
        printf ' %s | %s%s%% | %s | load: %s | mem: %s | %s | %(%d.%m.%Y %H:%M:%S)T \n' \
          "$ips" "$temp" "$cpu" "$gpu" "$load" "$mem" "''${vol:-♪ -}" -1
        sleep 1
      done
    '';
  };
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
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = false;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  nixpkgs.config.allowUnfree = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;

  services.openssh.enable = true;
  services.openssh.openFirewall = false;
  services.openssh.settings.PasswordAuthentication = false;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  services.tailscale.authKeyFile = "/var/lib/secrets/tailscale.key";

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
  # Monitors are on the Raphael iGPU; the RTX is compute-only and stays out of sway.
  # WLR_DRM_DEVICES is colon-separated, so the by-path name (pci-0000:0e:00.0-card) can't be used.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", SYMLINK+="dri/igpu"
    # NUCLEO-N657X0-Q: its on-board STLINK-V3EC, matched by serial so no other probe or DFU device is opened up.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3754", ATTR{serial}=="003300243234510337333934", MODE="0660", GROUP="dialout"
  '';
  programs.sway.extraSessionCommands = "export WLR_DRM_DEVICES=/dev/dri/igpu";
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
        status_command ${lib.getExe status}
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
      user.name = "marcelsachs";
      user.email = "sachsmarcel@proton.me";
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
    tinygrad
    stprogr
    stedgeai
    grok-build
    cursor-cli
  ];

  system.stateVersion = "26.05";
}
