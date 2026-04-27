#!/usr/bin/env bash

# Steam install script for Nintendo Switch 1 (l4t) by Sildur
# Based on "Kiri's Whimsical Automagic Steam-on-ARM script spectacular"

set -euo pipefail

exit_on_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Setup
STEAMROOT="$HOME/.local/share/Steam"
STEAMHOME="$HOME/.steam"
RTARM64ROOT="$STEAMROOT/steamrtarm64"

# Check if either Steam directory exists
if [ -d "$STEAMROOT" ] || [ -d "$STEAMHOME" ]; then
    echo "Steam directories already exist."
    read -p "A clean installation is required. Would you like to delete them now for a clean install? (y/N): " choice
    case "$choice" in 
        [yY][eE][sS]|[yY]) 
            echo "Deleting $STEAMROOT and $STEAMHOME..."
            rm -rf "$STEAMROOT"
            rm -rf "$STEAMHOME"
			# Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
			ln -fsn "$STEAMROOT" "$STEAMHOME/root"
			ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
            ;;
        *)
            echo "Abort: Clean installation is required to proceed."
            exit 1
            ;;
    esac
fi

if [ ! -x "$RTARM64ROOT" ]; then
	echo "Downloading steam bootstrap.."
	mkdir -p "$STEAMROOT/package"
	echo "publicbeta" > "$STEAMROOT/package/beta"
	wget -c -t 5 -O "$STEAMROOT/linuxarm64.zip" "https://client-update.steamstatic.com/bins_linuxarm64_linuxarm64.zip.f523fa87fc6b9b5435a5e7370cb0d664ef53b50b" || exit_on_error "steam bootstrap download failed (check your internet connection)"
	unzip -d "$STEAMROOT" "$STEAMROOT/linuxarm64.zip" "steamrtarm64/steam"
	chmod +x "$RTARM64ROOT/steam"
	rm -rf "$STEAMROOT/linuxarm64.zip"
fi

if [ ! -x "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt" ]; then
	echo "Downloading steam-runtime.."
	mkdir -p "$RTARM64ROOT/pv-runtime"
	wget -c -t 5 -O "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" "https://repo.steampowered.com/steamrt3c/images/latest-public-beta/steam-runtime-steamrt-arm64.tar.xz" || exit_on_error "steam runtime download failed (check your internet connection)"
	tar -xvf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" --directory "$RTARM64ROOT/pv-runtime"
	mv "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64" "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt"
	rm -rf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz"
fi

if [ ! -d "$STEAMROOT/compatibilitytools.d/SteamLinuxRuntime_sniper" ]; then
	echo "Downloading sniper_x86-64-runtime.."
	mkdir -p "$STEAMROOT/compatibilitytools.d/"
	wget -c -t 5 -O "$STEAMROOT/compatibilitytools.d/SteamLinuxRuntime_sniper.tar.xz" "https://repo.steampowered.com/steamrt3/images/latest-container-runtime-public-beta/SteamLinuxRuntime_sniper.tar.xz" || exit_on_error "sniper_x86-64 runtime download failed (check your internet connection)"
	tar -xvf "$STEAMROOT/compatibilitytools.d/SteamLinuxRuntime_sniper.tar.xz" --directory "$STEAMROOT/compatibilitytools.d"
    rm -rf "$STEAMROOT/compatibilitytools.d/SteamLinuxRuntime_sniper.tar.xz"
fi

if [ -x "$RTARM64ROOT/steam" ]; then
    echo "Starting Steam (Initial Update phase)..."
    export LD_LIBRARY_PATH="$RTARM64ROOT:${LD_LIBRARY_PATH-}"
    "$RTARM64ROOT/steam" "$@" || true
    
    echo "Steam exited. Downloading files to downgrade steam.."

    # temp dir for extraction
    TEMP_SD="$STEAMROOT/temp_sd"
    mkdir -p "$TEMP_SD"

	wget -q -t 5 -O- "https://github.com/SildurFX/Switchdeck/archive/refs/heads/main.tar.gz" | tar xz -C "$TEMP_SD" --strip-components=1 || exit_on_error "Failed to download/extract downgrade files"

    if [ -f "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" ]; then
        tar -xzf "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" -C "$STEAMROOT/linuxarm64"
    fi

    # Reassemble and extract steamrtarm64
    if [ -f "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.partaa" ]; then
        cat "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.part"* > "$TEMP_SD/steamrtarm64.tar.gz"
        tar -xzf "$TEMP_SD/steamrtarm64.tar.gz" -C "$STEAMROOT/steamrtarm64"
        rm -f "$TEMP_SD/steamrtarm64.tar.gz"
    fi

    # move files and scripts
    cp -f  "$TEMP_SD/files/downgrade/steam.cfg" "$STEAMROOT/steam.cfg"
    cp -f  "$TEMP_SD/files/steam/launch-steam.sh" "$STEAMROOT/"
    cp -f  "$TEMP_SD/files/steam/steam-boot.sh" "$STEAMROOT/"
    mkdir -p "$STEAMROOT/compatibilitytools.d"
    cp -rf "$TEMP_SD/files/steam/compatibilitytools.d/." "$STEAMROOT/compatibilitytools.d/"

    # Cleanup
    rm -rf "$TEMP_SD"

    # Overkill but make sure everything is executable
	chmod -R +x "$STEAMROOT"

    echo "Launching Steam"
    exec "$STEAMROOT/launch-steam.sh" "$@"
fi
