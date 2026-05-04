#!/usr/bin/env bash

# verbose
# export PS4='${LINENO}: '
# set -x

# Documentation:
# Steam:  https://gist.github.com/davispuh/6600880
#         https://developer.valvesoftware.com/wiki/Command_line_options_(Steam)
# Proton: https://github.com/valvesoftware/proton
#         https://github.com/CachyOS/proton-cachyos
# DXVK:	  https://github.com/pythonlover02/DXVK-Sarek/blob/main/dxvk.conf
# Box64:  https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md

########################################################################################################################################

# Proton-CachyOS:
export PROTON_USE_SDL=1                 # Fix for controller issues with joycons
export PROTON_USE_WOW64=1               # Use wow64 mode
export PROTON_DXVK_SAREK=1              # Use the dxvk-sarek fork as DXVK replacement for older GPUs that don't support Vulkan 1.3 (supports Vulkan 1.1+)

# Wine:
export WINEESYNC=0                      # Supported but crashes dxvk and only works with wined3d
export PROTON_NO_ESYNC=1                # set WINEESYNC=1 and PROTON_NO_ESYNC=0 to enable esync
export PROTON_NO_FSYNC=1                # requires Kernel 5.x+
export PROTON_NO_NTSYNC=1               # requires Kernel 6.12+
export STAGING_WRITECOPY=1              # Uses copy-on-write for shared memory to improve stability and prevent corruption
export STAGING_SHARED_MEMORY=1          # Enables shared memory segments to reduce overhead and improve startup times
export __GL_THREADED_OPTIMIZATIONS=1    # Enable driver-side multi-threading to reduce CPU bottlenecks in OpenGL games

# DXVK:
export DXVK_ALL_CORES=1                 # Overwrite the way we assign cores to compile shaders. By default use roughly half the available CPU cores for background compilation.

# Box64:
export BOX64_PROFILE=fast               # [safest safe default fast fastest] Predefined environment variables with compatibility or performance in mind
export BOX64_X87_NO80BITS=1             # [0=default 1] Behaviour of x87 80bits long double.
export BOX64_DYNAREC_CALLRET=1          # [0=default 1 2] Optimize CALL/RET opcodes.
export BOX64_DYNAREC_BIGBLOCK=3         # [0 1 2=default 3] Enable building bigger DynaRec code blocks for better performance
# unstable
# export BOX64_DYNAREC_WAIT=0           # [0 1=default] Wait or not for the building of a DynaRec code block to be ready
# export BOX64_DYNAREC_DIRTY=2          # [0=default 1 2] Allow continue running a block that is unprotected and potentially dirty.

# Disable logging:
export BOX64_LOG=0                      # [0 1 2 3] Enable or disable Box64 logs, default value is 0 if stdout is not terminal, 1 otherwise
export WINEDEBUG=-all                   # https://gitlab.winehq.org/wine/wine/-/wikis/Debug-Channels
export DXVK_LOG_LEVEL=none              # [none error warn info debug] Controls message logging

# Steam launch flags:
STEAM_FLAGS=""
STEAM_FLAGS+=" -vrskip"                 # Skip VR initialization entirely no matter who asks for it
STEAM_FLAGS+=" -vrdisable"             	# Disable VR - never even try to load OpenVR DLLs
STEAM_FLAGS+=" -noverifyfiles"         	# Prevents from the client from checking files integrity, especially useful when testing localization.
STEAM_FLAGS+=" -nocrashmonitor"        	# Disables the Steam crash monitor
STEAM_FLAGS+=" -cef-disable-breakpad"  	# Disables breakpad in crash dumps
STEAM_FLAGS+=" -cef-disable-js-logging" # Disables console and log file logging of JS console events

########################################################################################################################################

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "launch-steam.sh[$$]: $*" >&2 || :
}

# Overwrites defaults and enables tracing if launched from a terminal (Konsole)
if [ -t 1 ]; then
    echo "Debug Mode Active (Terminal Detected)"
    set -x
    export BOX64_LOG=1
    export WINEDEBUG=""
    export DXVK_LOG_LEVEL=info
else
    exec > /dev/null 2>&1
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

		"$STEAMROOT/steamrtarm64/steam" "$@" $STEAM_FLAGS
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