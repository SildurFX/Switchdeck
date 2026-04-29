#!/usr/bin/env bash

# verbose
# export PS4='${LINENO}: '
# set -x

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "launch-steamRT3.sh[$$]: $*" >&2 || :
}

STEAMROOT="$HOME/.local/share/Steam"

# SteamRT3 client flag, does nothing on ARM64 yet
# touch "$STEAMROOT/.steam-enable-steamrt64-client"

if [ -x "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt" ]; then
	# we're ready to launch the runtime-service and steam
    log "Starting steam-runtime-launcher-service"
    "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt/pressure-vessel/bin/steam-runtime-launcher-service" \
		--bus-name com.steampowered.PressureVessel.LaunchAlongsideSwitchdeck \
		--alongside-steam \
		--verbose &
    log "Starting steam inside the steam-runtime"
    "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt/_v2-entry-point" -- "$STEAMROOT/launch-steam.sh" "$@"
else
    log "steam-runtime and pressure-vessel are missing, check your installation"
fi
