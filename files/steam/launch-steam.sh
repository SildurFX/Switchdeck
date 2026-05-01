#!/usr/bin/env bash

# verbose
# export PS4='${LINENO}: '
# set -x

# Proton:
export PROTON_USE_SDL=1					# Fix for controller issues with joycons
export PROTON_USE_WOW64=1
export PROTON_DXVK_SAREK=1

# WINED3D:
export STAGING_SHARED_MEMORY=1
export __GL_THREADED_OPTIMIZATIONS=1

# BOX64:
export BOX64_PROFILE=fast
export BOX64_X87_NO80BITS=1
export BOX64_DYNAREC_CALLRET=1
export BOX64_DYNAREC_BIGBLOCK=3
# unstable
# export BOX64_DYNAREC_WAIT=0
# export BOX64_DYNAREC_DIRTY=2

# Wine sync
export WINEESYNC=0						# Supported but crashes dxvk and only works with wined3d
export PROTON_NO_ESYNC=1				# set WINEESYNC=1 and PROTON_NO_ESYNC=0 to enable esync
# Unsupported by Kernel 4.9:
export PROTON_NO_FSYNC=1				# requires Kernel 5.x+
export PROTON_NO_NTSYNC=1				# requires Kernel 6.12+

# Disable logging:
export BOX64_LOG=0
export WINEDEBUG=-all

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "launch-steam.sh[$$]: $*" >&2 || :
}

# Allow us to debug what's happening in the script if necessary
if [ "${STEAM_DEBUG-}" ]; then
	set -x
fi

export TEXTDOMAIN=steam
export TEXTDOMAINDIR=/usr/share/locale

MAGIC_RESTART_EXITCODE=42
STEAMROOT="$HOME/.local/share/Steam"
STEAMHOME="$HOME/.steam"

if [ ! -f "$STEAMROOT/.switchdeck-initial-launch" ]; then
	log "creating initial symlinks"
	ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
	ln -fsn "$STEAMROOT/linux32" "$STEAMHOME/sdk32"
	ln -fsn "$STEAMROOT/linux64" "$STEAMHOME/sdk64"
	ln -fsn "$STEAMROOT/linuxarm64" "$STEAMHOME/sdkarm64"
	ln -fsn "$STEAMROOT/ubuntu12_32" "$STEAMHOME/bin32"
	ln -fsn "$STEAMROOT/ubuntu12_64" "$STEAMHOME/bin64"	
	ln -fsn "$STEAMHOME/bin32" "$STEAMHOME/bin"
	ln -fsn "$STEAMROOT/steamrtarm64" "$STEAMROOT/steamrtarm32"	

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

	touch "$STEAMROOT/.switchdeck-initial-launch"	
fi

function has_beta_optin()
{
	local betafile="$STEAMROOT/package/beta"
	if [ ! -r "$betafile" ]; then
		# No beta file, not in beta
		return 1
	fi

	local betaname="$(<"$betafile")"
	local stablenames=( "" "steamdeck_stable" "chromeos_public_88ac3843c888c7adb9cd406fbac4ff7a7d2cde9b" )

	for name in "${stablenames[@]}"; do
		if [ "$betaname" == "$name" ]; then
			# Opted into one of the "stable" betas
			return 1
		fi
	done

	return 0
}

if has_beta_optin; then
    if [ -x "$STEAMROOT/steamrtarm64/steam" ]; then
        log "Starting Steam"
		# Flat ARM64 -> Nested ARM64 -> Flat x64 -> Nested x64
		_rtarm=$(ls -d "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt-arm64"/steamrt3c_platform_*/files 2>/dev/null | head -1)
		_rtx64=$(ls -d "$STEAMROOT/steamrt64/pv-runtime/steam-runtime-steamrt"/steamrt3c_platform_*/files 2>/dev/null | head -1)
		export LD_LIBRARY_PATH="$STEAMROOT/steamrtarm64${_rtarm:+:$_rtarm/lib/aarch64-linux-gnu:$_rtarm/lib}:$STEAMROOT/steamrt64${_rtx64:+:$_rtx64/lib/x86_64-linux-gnu:$_rtx64/lib}:${LD_LIBRARY_PATH-}"

        "$STEAMROOT/steamrtarm64/steam" "$@"
		#strace -osteam.s.log -ff -e trace=file -e trace=execve -s 1000 --no-abbrev "$STEAMROOT/steamrtarm64/steam" "$@"

        STATUS=$?

        # If steam requested to restart, then restart
        if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ] ; then
            log "Restarting Steam by request"
            exec "$0" "$@"
        fi
        exit $STATUS
    fi
fi

