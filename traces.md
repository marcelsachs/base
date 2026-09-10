# traces

Append-only. One entry per piece of work on this machine (rebuilds, udev, layout).

```
## YYYY-MM-DD HH:MM short-name

    commands

result: a few lines. No prompt dump.
```

## 2026-09-07 17:20 four-desks

    mv /n6lab /lab; mv /n6emu /lab/emu; mv ~/tinygrad /tinygrad
    split /docs into /lab/docs /drone/docs /sentry/docs
    nixos-rebuild: /dl /tinygrad tmpfiles, Chromium DownloadDirectory=/dl

result: four repos, no /docs or /traces on PATH. n6=/lab/tools/n6. emu check ok.

## 2026-09-07 17:35 operator-home

    users.sachs.home = /sachs
    rsync ssh grok config cursor vault from /home/sachs
    GROK_HOME=/sachs/.grok  HISTFILE=/sachs/.bash_history
    vim/git/bash stay in the flake

result: sachs is sudo operator. /sachs is login state, not a workspace. Re-login for $HOME.

## 2026-09-07 17:40 matrix-login

    tuigreet --background matrix
    /etc/tuigreet/config.toml kind=matrix
    rm -rf /home/sachs

result: HOME=/sachs. Old /home/sachs removed. Matrix rain is default on next greetd start (logout).

## 2026-09-07 17:32 chromium-pkg

    environment.systemPackages += chromium
    sudo nixos-rebuild switch --flake /etc/nixos#blackwell

result: /run/current-system/sw/bin/chromium -> chromium-152.0.7977.82. Super+d lists it.

## 2026-09-07 18:20 github-fresh

    bootstrap.sh clones lab/drone/sentry after ISO install
    Cursor workspace file:///lab. sentry README: no RTK
    pushed four repos (LFS PDFs verified byte-for-byte)
    archived GitHub docs + traces (gh token has no delete_repo)
    deleted origin cursor/stm32n657-embedded-learning-5287

result: live GitHub is blackwell, lab, drone, sentry. docs/traces archived.
        wipe: gh auth refresh -h github.com -s delete_repo
              && gh repo delete marcelsachs/docs --yes
              && gh repo delete marcelsachs/traces --yes
        /home stays FHS-empty. ISO is OS + bootstrap, not a full image.

## 2026-09-07 18:40 wipe-docs-traces

    gh repo delete marcelsachs/docs --yes
    gh repo delete marcelsachs/traces --yes

result: GitHub is only blackwell, lab, drone, sentry. Datasheets stay in the desk repos.

## 2026-09-07 19:16 comments

    READMEs, AGENTS, nix comments: facts only. writing rule in AGENTS.md

result: no defence-of-the-choice prose.

## 2026-09-07 20:14 chromium-widevine

    chromium.override { enableWideVine = true; }
    sudo nixos-rebuild switch --flake /etc/nixos#blackwell
    kill chromium; swaymsg exec chromium

result: VdoCipher 2006 (device not compatible) on Pyjama Cafe C course.
        WidevineCdm 4.10.3050.0 in chromium-unwrapped-152.0.7977.82-wv.
        Player: Mental Model of the System 00:08 -> 00:23 / 16:42.

## 2026-09-07 21:19 lab-to-nucleo

    sudo mv /lab /nucleo
    gh repo rename nucleo --yes
    sudo nixos-rebuild switch --flake /etc/nixos#blackwell
    sudo rm /lab

result: PATH and tmpfiles /nucleo. github.com/marcelsachs/nucleo. no /lab.

## 2026-09-08 13:30 stm32n6-desks

    AGENTS/README: sentry = Nucleo N657 + STEVAL-66GYMAI1 + moteus-C1 + GL35
    udev: drop Basler 2676. keep ST-LINK, OpenMV 37c5, fdcanusb 16d0:0d60
    sudo nixos-rebuild switch --flake /etc/nixos#blackwell

result: AGENTS sentry row is Nucleo N657 + STEVAL-66GYMAI1. udev ST-LINK, OpenMV 37c5, fdcanusb.
        generation /nix/store/kzjby45dziab6na8qannrik978xmjqrj-nixos-system-blackwell-26.11.20260905.c043004
        99-local.rules has no Basler 2676. udevd restarted.

## 2026-09-08 13:50 two-desks

    PATH/tmpfiles drop /nucleo. STM32_PRG_PATH=/dl/stprogr
    bootstrap clones drone + sentry. setup-st -> /dl
    sudo nixos-rebuild switch --flake /etc/nixos#blackwell
    sudo rm -rf /nucleo

result: desks are /drone and /sentry. vendor /dl/stprogr /dl/stedgeai. tmpfiles without /nucleo.

## 2026-09-08 14:10 no-vendor-in-dl

    rm -rf /dl/stprogr /dl/stedgeai
    rm -rf /sachs/st_ai_output /sachs/st_ai_ws
    n6 load: OpenOCD + gdb n6-load.

result: /dl is Chromium downloads. load is OpenOCD. stedgeai cwd dumps gone.

## 2026-09-08 17:56 tools-on-blackwell

    tools.nix: gcc gdb gcc-arm-embedded OpenOCD-n6 n6 hw stprogr stedgeai
    /etc/n6/boards: openmv MiniE + nucleo V3EC (two USB ports)
    vendor trees /opt/st via setup-st. desks drop flakes.

result: cd /drone && make; n6 load vision/build/vision.elf
        cd /sentry && make; n6 load fw/blink/build/blink.elf

## 2026-09-09 00:32 agent-human

    users: agent 1001 /azor, human 1002 /human, sachs 1000 SSH
    tuigreet --user-menu 1001-1002. greetd session: agent sway-azor else sway
    strip git name, hashedPassword, GROK_HOME=/sachs, cursor/obsidian/bambu/widevine
    azor-grok + sandbox desks. /etc/nixos root:wheel. desks agent:users 2775

result: seat is agent | human. sachs arrive is /sachs/env.

## 2026-09-09 10:20 tuigreet-agent-human

    drop tuigreet --remember (lastuser=sachs hid UID 1001–1002 menu)
    empty agent/human GECOS so menu is agent | human
    sudo rm /var/cache/tuigreet/lastuser
    nixos-rebuild switch --elevate sudo --flake /etc/nixos#blackwell

result: greetd.toml has no --remember. greetd not restarted. next logout: Enter then agent | human.

## 2026-09-09 10:40 seat-enter

    drop agent/human/sachs unix seats and azor/human homes
    greetd autologin lab → sway (raptors) → foot /etc/blackwell/seat
    enter NAME → nix shell /env/NAME. tools on PATH (tools.nix)
    lab uid 1003. activation removed sachs (keep /sachs). SSH lab@ + helios.pub
    userdel agent human. ln -sfn /sachs/env /env/sachs
    ln -sfn /sachs/env /env/sachs

result: no tuigreet menu. first terminal lists enter / n6 / hw / tiny / setup-st.

## 2026-09-09 10:48 boot-welcome

    boot.loader.timeout = 0
    greetd: no text greeter. initial_session + default_session = sway lab
    docs: no helios

result: power on → raptors + welcome terminal. no user menu.

## 2026-09-09 10:52 st-in-dl

    drop setup-st from PATH and welcome
    drop /opt/st. stprogr/stedgeai find CLI under /dl

result: vendor zips unzip in /dl. no /opt.

## 2026-09-09 10:57 welcome

    welcome: net, system, tools, probes, enter NAME (user|agent)
    seat and SSH loginShellInit both run it

result: start point is the same screen local and remote.
## 2026-09-09 10:45 greetd-nvidia-env

    greetd session exports WLR_DRM_DEVICES=/dev/dri/nvidia-card before sway
    useTextGreeter. enter sachs: /env/sachs flake + neo_qwertz on-enter

result: needs nixos-rebuild as lab (uid 1000 no longer in passwd).
## 2026-09-09 11:10 azor-seat-setup-st

    users.users.azor uid 1004 home /azor. greetd autologin azor
    setup-st in tools.nix: zip in /dl -> /opt/st/{progr,edgeai}
    stprogr/stedgeai exec from /opt/st. not /dl
    welcome does not list setup-st

result: source ready. activated generation still lab until rebuild.
## 2026-09-09 11:20 no-home

    azor home=/azor. tmpfiles R /home. override systemd Q /home
    leftover /home/lab removed on next tmpfiles

result: no /home after switch+reboot.

## 2026-09-09 12:10 root-n6

    rm -rf /human /sachs /env
    greetd autologin root. HOME=/. GROK_HOME=/.grok. /AGENTS.md
    drop azor, enter, /env. n6 uses the plugged ST-LINK. gpu = tinygrad+CUDA
    drop-azor userdel after reboot when azor is not logged in

result: boot → welcome → grok | gpu | n6. no people accounts.
        greetd is root. reboot to leave leftover uid 1004. then rm -rf /azor.

## 2026-09-09 12:25 neoqwertz

    console.keyMap = neoqwertz
    services.xserver.xkb = de / neo_qwertz
    sway input type:keyboard xkb_layout de xkb_variant neo_qwertz
    swaymsg input type:keyboard xkb_variant neo_qwertz
    loadkeys -u neoqwertz
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: default layout German (Neo, QWERTZ). console map neoqwertz (unicode).

## 2026-09-09 12:28 chromium-root

    chromium.override commandLineArgs = --no-sandbox --disable-gpu-sandbox
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: chromium as root. without flags: "Running as root without --no-sandbox is not supported".

## 2026-09-09 12:40 azor-seat

    users.azor uid 1004 home=/azor wheel. greetd autologin azor
    drop-azor removed. Chromium sandbox on. GROK_HOME=$HOME/.grok
    desks 0775 azor wheel. sudo NOPASSWD wheel
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: seat is azor. root is SSH + rebuild. greetd restart to sit.

## 2026-09-09 12:50 sachs-seat

    drop azor. users.sachs uid 1000 home=/sachs wheel
    greetd autologin sachs. desks sachs:wheel. GROK_HOME=/sachs/.grok
    tmpfiles R /azor. nixos-rebuild switch --flake /etc/nixos#blackwell

result: only sachs + root. seat is sachs. uid 1000.

## 2026-09-09 13:05 drop-root-agents

    drop tmpfiles L+ /AGENTS.md
    rm /AGENTS.md /.grok/AGENTS.md
    charter /etc/nixos/AGENTS.md. GROK_HOME=/sachs/.grok/AGENTS.md
    keep /drone /sentry /tinygrad AGENTS.md
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: no /AGENTS.md. grok charter is the flake + $GROK_HOME symlink.

## 2026-09-09 13:13 waybar-tailscale

    waybar custom/tailscale: T: IPv4 from tailscale0 (tun operstate UNKNOWN)
    welcome: drop net
    rm -rf /.grok /tmp/old-docs
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: bar E W T. welcome has no addresses. root grok home gone.

## 2026-09-09 13:15 welcome-cmd

    welcome: only commands. drop system tools probes
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: first terminal is n6 / gpu / grok / hw / n6 check.

## 2026-09-09 13:17 root-home

    users.root.home default /root. drop HOME=/
    tmpfiles r/R /.bashrc /.bash_history /.viminfo /.cache /.config /.local /.nix-defexpr /.grok
    rm those plus empty /home
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: no root-seat dotfiles at /. root SSH is /root.

## 2026-09-09 13:19 waybar-gpu

    waybar custom/gpu: nvidia-smi utilization.gpu + temperature.gpu
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: bar GPU: N% N °C after CPU. down if nvidia-smi fails.

## 2026-09-09 13:24 waybar-cpu-gpu-fmt

    CPU: {temp}°C | {usage}%   GPU: {temp}°C | {util}%
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: bar CPU: 55°C | 42% GPU: 42°C | 69%.

## 2026-09-09 13:26 waybar-sep

    | between sections only. CPU: 55°C 42%  GPU: 42°C 69%
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: bar E | W | T | CPU | GPU | load | mem | vol | clock.

## 2026-09-09 13:28 no-welcome

    drop welcome, seat, loginShellInit. sway exec foot
    waybar: drop custom/sep
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: boot is Sway + foot. bar has no |.

## 2026-09-09 13:31 downloads

    mv /dl /downloads
    tmpfiles d /downloads, R /dl
    Chromium DownloadDirectory=/downloads. DL=/downloads
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: downloads are /downloads. /dl gone.

## 2026-09-09 13:39 usb-backup

    tar /etc/nixos /drone /sentry -> Transcend 32GB backup/blackwell-20260909-1339
    rsync 32GB backup/ -> Kingston 500GB backup/
    sha256 OK on 500GB. rm 32GB backup/ and nix/
    32GB left: ISO/ st/ ventoy/

result: snapshot on Kingston /backup/blackwell-20260909-1339.
        nixos.tar.gz 3.8M  drone.tar.gz 206M  sentry.tar.gz 218M

## 2026-09-09 13:57 stprogr-nix

    CubeProgrammer 2.23.0: requireFile zip, izpack-unpack.py, wrap STM32_Programmer_CLI as stprogr
    drop setup-st, /opt/st, old stedgeai wrapper
    stedgeai-lin.zip is Qt online installer (ST login). no CLI tree in the zip.
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: stprogr --help -> STM32CubeProgrammer v2.23.0. store 1.5G. no /opt/st.

## 2026-09-09 14:45 stedgeai-nix

    create-offline stedgeai0400.stm32mcu (+ Neural-ART) -> /downloads/stedgeai-linux-offline 737M
    requireFile + silent install into store. wrap Utilities/linux/stedgeai
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: stedgeai --version -> ST Edge AI Core v4.0.1-20581 STM32CubeAI 12.0.1-RC2. store 2.4G.

## 2026-09-09 14:58 st-zips-usb-only

    cp nix-store stedgeai-linux-offline -> Ventoy st/ (32GB UUID FBDE-EAD7, 500GB UUID 2680-E05F)
    cmp OK vs store. rm /downloads/{SetupSTM32CubeProgrammer_linux_64.zip,stedgeai-lin.zip,stedgeai-linux-offline}
    rm -rf /tmp/cubeout /tmp/cubeprog /tmp/pyj /tmp/stedgeai-* /tmp/st-home* /tmp/st-inspect /tmp/st-packs
    requireFile prefetch path: /mnt/st/ after mount UUID FBDE-EAD7

result: ST blobs on Ventoy st/ + nix store. /downloads has no vendor zips. no /opt/st.

## 2026-09-09 15:34 install-st-prefetch

    install.sh: nix --store /mnt store add --mode flat the two Ventoy st/ blobs
    docs/install.md mount by UUID FBDE-EAD7 (both labels Ventoy)
    rsync /etc/nixos -> Ventoy nix/ on 32GB and 500GB

result: option 1. wipe + install.sh builds stprogr and stedgeai from USB st/.

## 2026-09-09 15:45 base-repo

    /etc/nixos git history reset. origin will be git@github.com:marcelsachs/base.git
    old blackwell .git saved at /sachs/blackwell.git.bak
    drop unused helios.pub. n6 check no longer names setup-st

result: working tree is the base snapshot. GitHub create/push needs helios (no key on this box).

## 2026-09-09 15:55 tmpfiles-trim-vim-clip

    drop tmpfiles R /opt/st /dl /home /human /azor /env and root-seat /.* dots
    keep home.conf override (systemd Q /home). rmdir leftover empty /home
    vimrc: TextYankPost -> wl-copy. this vim is -wayland -clipboard
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: tmpfiles only desks + grok links + /etc/nixos mode. yank goes to CLIPBOARD.

## 2026-09-09 16:05 nixos-trim

    drop unused path_del/path_prepend, duplicate git/chromium packages, .envrc, docs/README.md
    comments: keep pin/command/brick only

result: flake eval blackwell. git via programs.git. chromium is a package (programs.chromium is policies only).

## 2026-09-09 16:20 n6-trim

    n6 check: no stprogr/stedgeai. n6 dash gone. hw no GPU. drop gpu from PATH
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: n6 is info/load/mon/gdb/check. waybar gpu script unchanged.

## 2026-09-09 16:35 drop-sandbox-env

    rm sandbox.toml. n6 load no dashboard, kill openocd on exit. drop /etc/blackwell-env.sh
    CUDA_PATH in environment.variables. nixos-rebuild switch --flake /etc/nixos#blackwell

result: grok sandbox off (default). no BASH_ENV.

## 2026-09-09 19:20 gh

    environment.systemPackages += gh
    nixos-rebuild switch --flake /etc/nixos#blackwell

result: gh on PATH. GitHub push still needs `gh auth login`.









