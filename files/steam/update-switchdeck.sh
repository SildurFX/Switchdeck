#!/usr/bin/env bash

set -o pipefail
shopt -s failglob
set -u

# Check for terminal
if [ ! -t 0 ]; then
    if command -v konsole >/dev/null 2>&1; then
        exec konsole -e "$0" "$@"
    elif command -v gnome-terminal >/dev/null 2>&1; then
        exec gnome-terminal -- "$0" "$@"
    elif command -v xterm >/dev/null 2>&1; then
        exec xterm -e "$0" "$@"
    fi
fi

STEAMROOT="$HOME/.local/share/Steam"

# Check for old folder name and update to new structure
if [ -d "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt" ]; then
    echo "Old runtime structure detected. Migrating to -arm64 suffix.."
    mv -f "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt" "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt-arm64"
fi

echo "Checking for script updates.."
wget -t 5 -N -P "$STEAMROOT" "https://raw.githubusercontent.com/SildurFX/Switchdeck/refs/heads/main/files/steam/launch-steam.sh"
wget -t 5 -N -P "$STEAMROOT" "https://raw.githubusercontent.com/SildurFX/Switchdeck/refs/heads/main/files/steam/launch-steamRT3.sh"
wget -t 5 -N -P "$STEAMROOT" "https://raw.githubusercontent.com/SildurFX/Switchdeck/refs/heads/main/files/steam/update-switchdeck.sh"
chmod +x "$STEAMROOT/launch-steam.sh" "$STEAMROOT/launch-steamRT3.sh" "$STEAMROOT/update-switchdeck.sh"

# Restart if update-switchdeck.sh was updated
if [[ "$STEAMROOT/update-switchdeck.sh" -nt "$0" ]]; then
    echo "New version detected. Restarting script..."
    exec "$STEAMROOT/update-switchdeck.sh" "$@"
fi

# Verify controller permissions
if [ ! -w /dev/uinput ]; then
    echo "Controller permissions not found. Fixing.. (Requires sudo)"
    sudo sh -c "mkdir -p /etc/udev/rules.d && echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"' > /etc/udev/rules.d/70-uinput.rules"
    sudo modprobe uinput 2>/dev/null || true
    sudo udevadm control --reload-rules && sudo udevadm trigger --sysname-match=uinput
    echo "Done!"
fi

# Check for DXVK-Sarek update
SWITCHDECK_DIR="$HOME/.steam/steam/Switchdeck"
VERSION_FILE="$SWITCHDECK_DIR/dxvk-sarek_version.txt"
LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
LATEST_TAG=$(echo "$LATEST_JSON" | grep -Po '"tag_name": "\K.*?(?=")')

if [ "$LATEST_TAG" != "$(cat "$VERSION_FILE" 2>/dev/null)" ]; then
    echo "New DXVK-Sarek version found ($LATEST_TAG)! Updating.."
    URL=$(echo "$LATEST_JSON" | grep -Po '"browser_download_url": "\K.*?(?=")' | head -1)
    mkdir -p "$SWITCHDECK_DIR"
    rm -rf "$SWITCHDECK_DIR/x64" "$SWITCHDECK_DIR/x32"
    wget -q --show-progress "$URL" -O temp.tar.gz
    tar -xzf temp.tar.gz -C "$SWITCHDECK_DIR" --strip-components=1
    echo "$LATEST_TAG" > "$VERSION_FILE"
    rm temp.tar.gz
fi

read -p "Would you like to update Steam? (y/N): " choice
case "$choice" in 
    [yY][eE][sS]|[yY]) 
    echo "Updating Steam.."
    # use steamrt3 and x64 client to update steam
    touch "$STEAMROOT/.steam-enable-steamrt64-client"
    mv -f "$STEAMROOT/steam.cfg" "$STEAMROOT/steam.cfg.downgrade"
    mv -f "$STEAMROOT/linuxarm64" "$STEAMROOT/linuxarm64-downgrade"
    mv -f "$STEAMROOT/steamrtarm64" "$STEAMROOT/steamrtarm64-downgrade"

    "$STEAMROOT/steamrt64/steam" -forcesteamupdate -forcepackagedownload -exitsteam & wait $!

    echo "Downgrading arm64 client.."
    rm -f "$STEAMROOT/.steam-enable-steamrt64-client"
    mv -f "$STEAMROOT/steam.cfg.downgrade" "$STEAMROOT/steam.cfg"
    mv -f "$STEAMROOT/linuxarm64-downgrade" "$STEAMROOT/linuxarm64"
    mv -f "$STEAMROOT/steamrtarm64-downgrade" "$STEAMROOT/steamrtarm64"

    chmod -R +x "$STEAMROOT/linuxarm64" "$STEAMROOT/steamrtarm64"
    echo "Switchdeck update complete!"
;;
*)
    echo "Skipping Steam updates"
    exit
;;
esac