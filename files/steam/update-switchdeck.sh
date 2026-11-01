#!/usr/bin/env bash

# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3

set -o pipefail
shopt -s failglob
set -u

echo "Checking for Switchdeck updates.."

STEAMROOT="$HOME/.local/share/Steam"
SWITCHDECK_DIR="$HOME/.local/share/Steam/Switchdeck"

# Check for Switchdeck updates
LAUNCH_SHA_FILE="$SWITCHDECK_DIR/launch-steam.sha"
UPDATE_SHA_FILE="$SWITCHDECK_DIR/update-switchdeck.sha"
LAUNCH_JSON=$(wget -qO- "https://api.github.com/repos/SildurFX/Switchdeck/contents/files/steam/launch-steam.sh?ref=armv8.0-LSE")
UPDATE_JSON=$(wget -qO- "https://api.github.com/repos/SildurFX/Switchdeck/contents/files/steam/update-switchdeck.sh?ref=armv8.0-LSE")
LATEST_LAUNCH_SHA=$(echo "$LAUNCH_JSON" | sed -n 's/.*"sha": "\([^"]*\)".*/\1/p' | head -n 1)
LATEST_UPDATE_SHA=$(echo "$UPDATE_JSON" | sed -n 's/.*"sha": "\([^"]*\)".*/\1/p' | head -n 1)

if [ "$LATEST_LAUNCH_SHA" != "$(cat "$LAUNCH_SHA_FILE" 2>/dev/null)" ] || [ ! -f "$STEAMROOT/launch-steam.sh" ]; then
    wget -q --header="Accept: application/vnd.github.v3.raw" -O "$STEAMROOT/launch-steam.sh" "https://api.github.com/repos/SildurFX/Switchdeck/contents/files/steam/launch-steam.sh?ref=armv8.0-LSE"
    echo "$LATEST_LAUNCH_SHA" > "$LAUNCH_SHA_FILE"
    echo "Updating launch script... You may have to restart Steam to fully apply the update."
    touch "$SWITCHDECK_DIR/.needs_restart"
    sleep 2
fi
if [ "$LATEST_UPDATE_SHA" != "$(cat "$UPDATE_SHA_FILE" 2>/dev/null)" ] || [ ! -f "$STEAMROOT/update-switchdeck.sh" ]; then
    wget -q --header="Accept: application/vnd.github.v3.raw" -O "$STEAMROOT/update-switchdeck.sh" "https://api.github.com/repos/SildurFX/Switchdeck/contents/files/steam/update-switchdeck.sh?ref=armv8.0-LSE"
    echo "$LATEST_UPDATE_SHA" > "$UPDATE_SHA_FILE"
    echo "Updating update script... You may have to restart Steam to fully apply the update."
    touch "$SWITCHDECK_DIR/.needs_restart"
    sleep 2
fi

chmod +x "$STEAMROOT/launch-steam.sh" "$STEAMROOT/update-switchdeck.sh"

# Todo: Replace with arm64ec builds
# Check for DXVK-Sarek update
DX_DIR="$SWITCHDECK_DIR/DXVK"
VERSION_FILE="$SWITCHDECK_DIR/dxvk-sarek_version.txt"
LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
LATEST_TAG=$(echo "$LATEST_JSON" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)

if [ "$LATEST_TAG" != "$(cat "$VERSION_FILE" 2>/dev/null)" ] || [ ! -d "$DX_DIR" ]; then
    echo "Updating DXVK-Sarek to $LATEST_TAG.."
    DXVK_URL=$(echo "$LATEST_JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' | head -1)

    # protection fallback
    [ -z "$DXVK_URL" ] && { echo "Error: GitHub API URL empty. Aborting update to protect current installation."; return 1; }

    # Clean up old folders if they exist
    rm -rf "$SWITCHDECK_DIR/x64" "$SWITCHDECK_DIR/x32"
    rm -rf "$DX_DIR" && mkdir -p "$DX_DIR"

    wget -q --show-progress -c -t 5 -O "$DX_DIR/dxvk-sarek.tar.gz" "$DXVK_URL"
    tar -xzf "$DX_DIR/dxvk-sarek.tar.gz" --directory "$DX_DIR" --strip-components=1
    rm -f "$DX_DIR/dxvk-sarek.tar.gz"

    echo "$LATEST_TAG" > "$VERSION_FILE"
    echo "DXVK-Sarek updated successfully."
fi

# Check if VKD3D is installed
VK_DIR="$SWITCHDECK_DIR/VKD3D"
VK_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.3.1/vkd3d-proton-2.3.1.tar.zst"

if [ ! -d "$VK_DIR" ]; then
    echo "Missing VKD3D folder. Downloading.."
    mkdir -p "$VK_DIR"

    # Check if zstd is missing
    command -v zstd >/dev/null || { echo "zstd is missing. Installing dependency.. (Requires sudo)"; [ -f /etc/fedora-release ] && sudo dnf install zstd -y || sudo apt-get install zstd -y; }

    wget -q --show-progress -c -t 5 -O "$VK_DIR/vkd3d.tar.zst" "$VK_URL"
    tar -xf "$VK_DIR/vkd3d.tar.zst" --directory "$VK_DIR" --strip-components=1
    rm -f "$VK_DIR/vkd3d.tar.zst"
    
    echo "VKD3D added successfully."
fi

EMU_DIR="$SWITCHDECK_DIR"
VERSION_FILE="$SWITCHDECK_DIR/LSE-Emu_version.txt"
LSE_JSON=$(wget -qO- "https://api.github.com/repos/SildurFX/LSE-Emu/releases/latest")
LSE_TAG=$(echo "$LSE_JSON" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)

# Check if the version file doesn't match or the core binary is completely missing
if [ "$LSE_TAG" != "$(cat "$VERSION_FILE" 2>/dev/null)" ] || [ ! -f "/usr/local/lib/liblse_emu.so" ]; then
    echo "Updating LSE-Emulator to $LSE_TAG.."
    LSE_URL=$(echo "$LSE_JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' | head -1)

    # protection fallback
    [ -z "$LSE_URL" ] && { echo "Error: GitHub API URL empty. Aborting update to protect current installation."; return 1; }

    wget -q --show-progress -c -t 5 -O "$EMU_DIR/liblse_emu.so" "$LSE_URL"

    sudo install -m 755 "$EMU_DIR/liblse_emu.so" /usr/local/lib/liblse_emu.so
    sudo ldconfig

    # Enforce safe entry check
    if [ ! -f /etc/ld.so.preload ] || ! grep -qFx "/usr/local/lib/liblse_emu.so" /etc/ld.so.preload; then
        echo "/usr/local/lib/liblse_emu.so" | sudo tee -a /etc/ld.so.preload > /dev/null
    fi

    echo "$LSE_TAG" > "$VERSION_FILE"
    echo "LSE-Emulator updated successfully."
fi

# Check if Proton 11 Arm64 is installed
if [ ! -d "$STEAMROOT/compatibilitytools.d/Proton 11.0-2e Armv8.0 (FEX)" ]; then
    echo "Downloading Proton 11.0-2e Armv8.0 (FEX).."
    mkdir -p "$STEAMROOT/compatibilitytools.d"

    if wget -q --show-progress -c -t 5 -O "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz" "https://github.com/SildurFX/Switchdeck-Extras/releases/download/Proton-11.0-2e-Armv8.0/Proton.11.0-2e.Armv8.0.FEX.tar.gz"; then
        echo "Extracting files (this may take a moment).."
        tar -xzf "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz" --directory "$STEAMROOT/compatibilitytools.d"
        rm -f "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz"

        touch "$SWITCHDECK_DIR/.fex_update2"
        echo "Proton 11.0-2e Armv8.0 (FEX) successfully installed."
    else
        echo "Error: Failed to download Proton 11.0-2e Armv8.0 (FEX)."
        exit 1
    fi
fi