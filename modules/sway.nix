{
  config,
  pkgs,
  lib,
  ...
}:
let
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
  shot = pkgs.writeShellApplication {
    name = "shot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.slurp
    ];
    text = ''
      dir=$HOME/shots
      mkdir -p "$dir"
      geom=$(slurp -d) || exit 1
      [[ $geom =~ ([0-9]+)x([0-9]+)$ ]] || exit 1
      if ((BASH_REMATCH[1] < 8 || BASH_REMATCH[2] < 8)); then
        echo "shot: selection ''${BASH_REMATCH[1]}x''${BASH_REMATCH[2]} is too small; click-drag a rectangle" >&2
        exit 1
      fi
      file=$dir/$(date +%F_%H-%M-%S).png
      grim -g "$geom" "$file"
      printf '%s\n' "$file"
    '';
  };
in
{
  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;
  environment.systemPackages = [
    pkgs.slurp
    shot
  ];
  # Monitors are on the Raphael iGPU; the RTX is compute-only and stays out of sway.
  # WLR_DRM_DEVICES is colon-separated, so the by-path name (pci-0000:0e:00.0-card) can't be used.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", SYMLINK+="dri/igpu"
  '';
  programs.sway.extraSessionCommands = "export WLR_DRM_DEVICES=/dev/dri/igpu";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
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
}
