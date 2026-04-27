#!/usr/bin/env bash

# verbose
# export PS4='${LINENO}: '
# set -x

# Proton:
export PROTON_USE_WOW64=1
export PROTON_DXVK_SAREK=1

# WINED3D:
export WINEESYNC=1
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

# Disable logging:
export BOX64_LOG=0
export WINEDEBUG=-all

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "steam-boot.sh[$$]: $*" >&2 || :
}
# This version interprets backslash escapes like echo -e
log_e () {
	echo -e "steam-boot.sh[$$]: $*" >&2 || :
}

# Allow us to debug what's happening in the script if necessary
if [ "${STEAM_DEBUG-}" ]; then
	set -x
fi
export TEXTDOMAIN=steam
export TEXTDOMAINDIR=/usr/share/locale

log_opened=

STEAMROOT="$(cd "$(dirname "$0")" && echo $PWD)"
if [ -z "${STEAMROOT}" ]; then
	log $"Couldn't find Steam root directory from "$0", aborting!"
	exit 1
fi
STEAMDATA="$STEAMROOT"
if [ -z ${STEAMEXE-} ]; then
  STEAMEXE=`basename "$0" .sh`
fi

PLATFORM=steamrtarm64

MAGIC_RESTART_EXITCODE=42

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
    if [ -x "$STEAMROOT/$PLATFORM/steam" ]; then
        log "Starting SteamRT3 Steam"
        export LD_LIBRARY_PATH="$STEAMROOT/$PLATFORM:${LD_LIBRARY_PATH-}"
        "$STEAMROOT/$PLATFORM/steam" "$@"
		#strace -osteam.s.log -ff -e trace=file -e trace=execve -s 1000 --no-abbrev "$STEAMROOT/$PLATFORM/steam" "$@"

        STATUS=$?

        # If steam requested to restart, then restart
        if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ] ; then
            log "Restarting SteamRT3 Steam by request"
            exec "$0" "$@"
        fi
        exit $STATUS
    fi
fi
