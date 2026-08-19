#!/usr/bin/env bash
set -euo pipefail
h=${HOME:-/sachs}
d=$h/stcubeprogr
if [[ ! -x $d/bin/STM32_Programmer_CLI ]]; then
  shopt -s nullglob
  z=(/tmp/downloads/SetupSTM32CubeProgrammer*.zip /tmp/downloads/*stm32cubeprg*.zip)
  [[ -f $h/base/stcubeprogr.zip ]] && z+=("$h/base/stcubeprogr.zip")
  zip=${1:-${z[0]-}}
  [[ -f ${zip-} ]]
  t=$(mktemp -d)
  trap 'rm -rf "$t"' EXIT
  bsdtar -xf "$zip" -C "$t"
  cat >"$t/auto-install.xml" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
<com.st.CustomPanels.CheckedHelloPorgrammerPanel id="Hello.panel"/>
<com.izforge.izpack.panels.info.InfoPanel id="Info.panel"/>
<com.izforge.izpack.panels.licence.LicencePanel id="Licence.panel"/>
<com.st.CustomPanels.TargetProgrammerPanel id="target.panel">
<installpath>$d</installpath>
</com.st.CustomPanels.TargetProgrammerPanel>
<com.st.CustomPanels.AnalyticsPanel id="analytics.panel"/>
<com.st.CustomPanels.PacksProgrammerPanel id="Packs.panel">
<pack index="0" name="Core Files" selected="true"/>
<pack index="1" name="STM32CubeProgrammer" selected="true"/>
<pack index="2" name="STM32TrustedPackageCreator" selected="true"/>
</com.st.CustomPanels.PacksProgrammerPanel>
<com.izforge.izpack.panels.install.InstallPanel id="Install.panel"/>
<com.izforge.izpack.panels.shortcut.ShortcutPanel id="Shortcut.panel"/>
<com.st.CustomPanels.FinishProgrammerPanel id="finish.panel"/>
</AutomatedInstallation>
EOF
  cd "$t"
  ./jre/bin/java -jar SetupSTM32CubeProgrammer-*.exe "$t/auto-install.xml"
  trap - EXIT
  rm -rf "$t"
fi
mkdir -p "$h/.local/bin"
printf '#!/bin/sh\nexec "%s/bin/STM32CubeProgrammer" "$@"\n' "$d" >"$h/.local/bin/progr"
printf '#!/bin/sh\nexec "%s/bin/STM32_Programmer_CLI" "$@"\n' "$d" >"$h/.local/bin/progr-cli"
chmod +x "$h/.local/bin/progr" "$h/.local/bin/progr-cli"
r=$d/Drivers/rules
if ! cmp -s "$r/49-stlinkv3.rules" /etc/udev/rules.d/49-stlinkv3.rules 2>/dev/null; then
  sudo cp "$r/49-stlinkv2.rules" "$r/49-stlinkv2-1.rules" "$r/49-stlinkv3.rules" "$r/50-usb-conf.rules" /etc/udev/rules.d/
  sudo udevadm control --reload-rules
  sudo udevadm trigger
fi
