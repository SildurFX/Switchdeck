#!/usr/bin/env bash

set -o pipefail
shopt -s failglob
set -u

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

echo "Updating steam.."
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