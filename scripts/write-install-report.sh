#!/usr/bin/env bash
set -euo pipefail
log=$1
out=$2
secs=${3:-}
root=${ROOT:-/mnt}

esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
val() { [[ -f $1 ]] && tr -d '\n' <"$1" || echo —; }

hostname=$(val "$root/etc/hostname")
lang=$(awk -F= '/^LANG=/{print $2}' "$root/etc/locale.conf" 2>/dev/null || echo —)
keymap=$(awk -F= '/^KEYMAP=/{print $2}' "$root/etc/vconsole.conf" 2>/dev/null || echo —)
user=$(awk -F: '$3==1000{print $1}' "$root/etc/passwd" 2>/dev/null || echo —)
home=$(awk -F: '$3==1000{print $6}' "$root/etc/passwd" 2>/dev/null || echo —)
uuid=$(awk '/^options /{for(i=1;i<=NF;i++) if($i ~ /^root=UUID=/){sub(/^root=UUID=/,"",$i); print $i}}' \
  "$root/boot/loader/entries/arch.conf" 2>/dev/null || echo —)
kernel=$(ls "$root/usr/lib/modules" 2>/dev/null | head -n1 || echo —)
disk=$(lsblk -dn -o NAME,SIZE /dev/nvme0n1 2>/dev/null || echo —)
root_total=$(df -h "$root" 2>/dev/null | awk 'NR==2{print $2}')
root_used=$(df -h "$root" 2>/dev/null | awk 'NR==2{print $3}')
swap=$(ls -lh "$root/swapfile" 2>/dev/null | awk '{print $5}')
rootfs="${root_total:-—} total, ${root_used:-—} used"
[[ -n ${swap:-} ]] && rootfs="$rootfs, $swap swap"
bootfs=$(df -h "$root/boot" 2>/dev/null | awk 'NR==2{print $2" total, "$3" used"}')
pubkey=$(val "$root${home:-/sachs}/.ssh/id_ed25519.pub")
services=
for s in sshd iwd systemd-networkd systemd-resolved bluetooth tailscaled; do
  st=$(systemctl --root="$root" is-enabled "$s" 2>/dev/null || true)
  [[ $st == enabled ]] && services=${services:+$services, }$s
done
[[ -n $services ]] || services=—
mins=; [[ -n $secs && $secs != *[!0-9]* ]] && mins="$((secs/60))m $((secs%60))s"

body=$(esc <"$log")
cat >"$out" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>blackwell install</title>
<style>
body{margin:0;font:15px/1.55 system-ui,sans-serif;background:#0f1419;color:#e7ecf3}
main{max-width:58rem;margin:0 auto;padding:2rem 1.25rem 4rem}
h1{font-size:1.55rem;margin:0 0 .35rem}
h2{font-size:1.1rem;margin:2rem 0 .75rem;padding-bottom:.35rem;border-bottom:1px solid #2a3548;color:#5b9fd4}
.ok{display:inline-block;background:#3d9a6a;color:#fff;font-size:.8rem;font-weight:650;padding:.2rem .55rem;border-radius:999px}
.meta{color:#8b9bb4;margin:0 0 1.5rem}
table{width:100%;border-collapse:collapse;font-size:.9rem;margin:.5rem 0 1rem}
th,td{text-align:left;padding:.45rem .6rem;border:1px solid #2a3548;vertical-align:top}
th{background:#1a2332;color:#8b9bb4;font-weight:600;width:11rem}
code,pre{font-family:ui-monospace,monospace;font-size:.82rem}
code{background:#0b1018;padding:.1em .35em;border-radius:4px;border:1px solid #2a3548}
code.pub{display:block;word-break:break-all;white-space:pre-wrap}
pre{background:#0b1018;border:1px solid #2a3548;border-radius:8px;padding:.85rem 1rem;overflow:auto;max-height:75vh;line-height:1.4;white-space:pre}
</style>
</head>
<body>
<main>
<h1>blackwell install <span class="ok">OK</span></h1>
<p class="meta">${secs:+${secs}s (${mins})}</p>
<table>
<tr><th>hostname</th><td>$(esc <<<"$hostname")</td></tr>
<tr><th>user</th><td>$(esc <<<"$user")</td></tr>
<tr><th>home</th><td>$(esc <<<"$home")</td></tr>
<tr><th>locale</th><td>$(esc <<<"$lang")</td></tr>
<tr><th>keymap</th><td>$(esc <<<"$keymap")</td></tr>
<tr><th>disk</th><td>$(esc <<<"$disk")</td></tr>
<tr><th>root UUID</th><td><code>$(esc <<<"$uuid")</code></td></tr>
<tr><th>root fs</th><td>$(esc <<<"$rootfs")</td></tr>
<tr><th>boot fs</th><td>$(esc <<<"$bootfs")</td></tr>
<tr><th>kernel</th><td>$(esc <<<"$kernel")</td></tr>
<tr><th>services</th><td>$(esc <<<"$services")</td></tr>
<tr><th>ssh pubkey</th><td><code class="pub">$(esc <<<"$pubkey")</code></td></tr>
<tr><th>duration</th><td>${secs:+${secs}s}</td></tr>
</table>
<h2>Log</h2>
<pre>${body}</pre>
</main>
</body>
</html>
EOF
