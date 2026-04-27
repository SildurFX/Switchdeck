#!/usr/bin/env bash

# verbose
#export PS4='${LINENO}: '
#set -x

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "launch-steam.sh[$$]: $*" >&2 || :
}
# This version interprets backslash escapes like echo -e
log_e () {
	echo -e "launch-steam.sh[$$]: $*" >&2 || :
}
exit_on_error () {
	log "$*"
	exit 1
}

STEAMROOT="$HOME/.local/share/Steam"
STEAMHOME="$HOME/.steam"
RTARM64ROOT="$STEAMROOT/steamrtarm64"

if [ -z "${STEAMROOT}" ]; then
	log $"Couldn't find Steam root directory from "$0", aborting!"
	exit 1
fi

# pid of running steam for this user
PIDFILE="$STEAMHOME/steam.pid"

# See if this is the initial launch of Steam
if [ ! -f "$PIDFILE" ]; then
	INITIAL_LAUNCH=true
else
	INITIAL_LAUNCH=false
fi

if [ "$INITIAL_LAUNCH" = true ]; then
	log "creating initial symlinks"
	ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
	ln -fsn "$STEAMROOT/linux32" "$STEAMHOME/sdk32"
	ln -fsn "$STEAMROOT/linux64" "$STEAMHOME/sdk64"
	ln -fsn "$STEAMROOT/linuxarm64" "$STEAMHOME/sdkarm64"
	ln -fsn "$STEAMROOT/ubuntu12_32" "$STEAMHOME/bin32"
	ln -fsn "$STEAMROOT/ubuntu12_64" "$STEAMHOME/bin64"	
	ln -fsn "$STEAMHOME/bin32" "$STEAMHOME/bin"

	# Add steam to path
	mkdir -p "$HOME/.local/bin"
	ln -fsn "$STEAMROOT/launch-steam.sh" "$HOME/.local/bin/steam"

    # Setup desktop path and icon
    MENU_DIR="$HOME/.local/share/applications"
    mkdir -p "$MENU_DIR"

    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
    mkdir -p "$DESKTOP_DIR"

    DESKTOP_FILE="$MENU_DIR/Steam.desktop"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Steam
Comment=Launch Steam
Exec=$HOME/.local/bin/steam %U
Icon=$STEAMROOT/public/steam_tray_48.tga
Terminal=false
Type=Application
Categories=Game;
MimeType=x-scheme-handler/steam;
EOF
    chmod +x "$DESKTOP_FILE"
    ln -fs "$DESKTOP_FILE" "$DESKTOP_DIR/Steam.desktop"
    update-desktop-database "$MENU_DIR" 2>/dev/null
fi

# enable the SteamRT3 client flag, even though this does nothing on ARM64 yet
touch "$STEAMROOT/.steam-enable-steamrt64-client"

if [ -x "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt" ]; then
	# we're ready to launch the runtime-service and steam
    log "Starting steam-runtime-launcher-service"
    "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt/pressure-vessel/bin/steam-runtime-launcher-service" \
		--bus-name com.steampowered.PressureVessel.LaunchAlongsideSwitchdeck \
		--alongside-steam \
		--verbose &
    log "Starting steamexe inside the steam-runtime"
    "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt/_v2-entry-point" -- "$STEAMROOT/steam-boot.sh" "$@"
else
    log "steam-runtime and pressure-vessel are missing, check your installation"
fi
