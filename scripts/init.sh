#!/usr/bin/env bash
set -Eeuo pipefail
PUID=${PUID:-1000}
PGID=${PGID:-1000}
[[ "$PUID" =~ ^[0-9]+$ && "$PGID" =~ ^[0-9]+$ && "$PUID" != 0 && "$PGID" != 0 ]] || { echo 'PUID and PGID must be nonzero integers' >&2; exit 1; }
groupmod -o -g "$PGID" ubuntu
usermod -o -u "$PUID" -g "$PGID" ubuntu
mkdir -p /data/{manager,server,wine,steamcmd,home}
chown "$PUID:$PGID" /data /data/{manager,server,wine,steamcmd,home}
# Preserve config, state, backups and a manually updated manager on restarts.
if [[ ! -f /data/manager/SCUM-Server-Automation.exe ]]; then
  cp -n /opt/scumsa/SCUM-Server-Automation.exe /data/manager/
  chown "$PUID:$PGID" /data/manager/SCUM-Server-Automation.exe
fi
cd /data/manager
# Start a private display, then replace the shell with Wine so tini forwards SIGINT
# directly to the manager rather than to xvfb-run's shell wrapper.
export DISPLAY=:99
gosu ubuntu Xvfb "$DISPLAY" -screen 0 1280x1024x24 -nolisten tcp &
exec gosu ubuntu wine /data/manager/SCUM-Server-Automation.exe