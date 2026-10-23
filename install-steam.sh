#!/usr/bin/env bash

# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3

set -euo pipefail

exit_on_error() {
    printf "\nERROR: %s\n" "$1" >&2
    exit 1
}

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

# Setup
STEAMHOME="$HOME/.steam"
STEAMROOT="$HOME/.local/share/Steam"
RTARM64ROOT="$STEAMROOT/steamrtarm64"
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")

# Uninstall conflicting packages and run Ubuntu specific setup
if command -v apt-get &>/dev/null; then
    dpkg -l | grep -q "^ii  steam-launcher " && {
    printf "\nFound conflicting system steam package. Uninstalling..\n"
    sudo apt-get remove -y steam-launcher
} || true

# check and install box64
if ! command -v box64 &>/dev/null; then
    printf "\nBox64 not found. Installing Box64 from Pi-Apps repository...\n"
    wget -qO- "https://pi-apps-coders.github.io/box64-debs/KEY.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/box64-archive-keyring.gpg
    echo "Types: deb
URIs: https://Pi-Apps-Coders.github.io/box64-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box64-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/box64.sources >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y box64-tegrax1
    sudo systemctl restart systemd-binfmt || true
    printf "\nBox64 installation complete.\n"
else
    printf "\nBox64 is already installed. Skipping installation.\n"
fi

# check and update GPU drivers to support vulkan 1.2
if [ ! -f /etc/apt/sources.list.d/theofficialgman-L4T-32-7.list ]; then
    printf "\nUpgrading GPU Drivers for Vulkan 1.2 support...\n"
    echo "deb [signed-by=/etc/apt/keyrings/theofficialgman-L4T.asc] https://theofficialgman.github.io/l4t-debs/ l4t noble-32-7" | sudo tee /etc/apt/sources.list.d/theofficialgman-L4T-32-7.list
    sudo rm -f /etc/apt/preferences.d/00-switch-bsp-restrictions
    sudo apt-get update -y
    sudo apt install -y -o Dpkg::Options::="--force-confdef" nvidia-bsp-32-7
    printf "\nGPU Drivers successfully upgraded. It is recommended to restart your system.\n"
    sleep 2
else
    printf "\nLatest GPU driver is already installed. Skipping installation.\n"
fi   

# fedora
elif command -v dnf &>/dev/null; then
    (rpm -q steam || rpm -q steam-launcher) &>/dev/null && {
        printf "\nFound conflicting system steam package. Uninstalling..\n"
        sudo dnf remove -y steam steam-launcher
    } || true
# arch
elif command -v pacman &>/dev/null; then
    pacman -Qq steam &>/dev/null && {
        printf "\nFound conflicting system steam package. Uninstalling..\n"
        sudo pacman -Rns --noconfirm steam
    } || true
fi

# Cleanup pre-existing/orphaned steam desktop files
for file in "$HOME/.local/share/applications/Steam.desktop" \
            "$HOME/.local/share/applications/steam.desktop" \
            "/usr/local/share/applications/Steam.desktop" \
            "/usr/local/share/applications/steam.desktop" \
            "/usr/share/applications/Steam.desktop" \
            "/usr/share/applications/steam.desktop" \
            "$DESKTOP_DIR/Steam.desktop" \
            "$DESKTOP_DIR/steam.desktop"; do
    if [ -f "$file" ]; then
        if [[ "$file" == /usr/* ]]; then
            sudo rm -f "$file"
        else
            rm -f "$file"
        fi
    fi
done

command -v update-desktop-database &>/dev/null && update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true

# Check if either Steam directory exists
if [ -d "$STEAMROOT" ] || [ -d "$STEAMHOME" ]; then
    printf "\nSteam directories already exist.\n"
    read -p "A clean installation is recommended. Would you like to delete them now? (y/N): " choice
    case "$choice" in 
        [yY][eE][sS]|[yY]) 
            printf "\nDeleting %s and %s...\n" "$STEAMROOT" "$STEAMHOME"
            rm -rf "$STEAMROOT"
            rm -rf "$STEAMHOME"
			# Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
            ;;
        *)
            printf "\nContinuing with dirty installation..\n"
            shopt -s extglob dotglob
            eval "rm -rf \"$STEAMROOT\"/!(compatibilitytools.d|depotcache|steamapps|userdata)"
            rm -rf "$STEAMHOME"
            # Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
            ;;
    esac
else
    # Fresh installation
    printf "\nNo existing Steam installation found. Performing fresh setup..\n"
    mkdir -p "$STEAMROOT"
    mkdir -p "$STEAMHOME"
    ln -fsn "$STEAMROOT" "$STEAMHOME/root"
    ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
fi

if [ ! -x "$RTARM64ROOT" ]; then
    printf "\nDownloading steam bootstrap..\n"
    mkdir -p "$STEAMROOT/package"
    rm -f "$STEAMROOT/package/beta"
    echo "publicbeta" > "$STEAMROOT/package/beta"
    chmod 444 "$STEAMROOT/package/beta"
	wget -q --show-progress -c -t 5 -O "$STEAMROOT/linuxarm64.zip" "https://client-update.steamstatic.com/bins_linuxarm64_linuxarm64.zip.f523fa87fc6b9b5435a5e7370cb0d664ef53b50b" || exit_on_error "steam bootstrap download failed (check your internet connection)"
    unzip -d "$STEAMROOT" "$STEAMROOT/linuxarm64.zip" "steamrtarm64/steam"
    chmod +x "$RTARM64ROOT/steam"
    rm -rf "$STEAMROOT/linuxarm64.zip"
fi

if [ ! -x "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64" ]; then
	printf "\nFetching current Steam runtime version..\n"
    VERSION=$(wget -qO- "https://repo.steampowered.com/steamrt3c/images/latest-public-beta.txt" | tr -d '[:space:]') && [ -n "$VERSION" ] || exit_on_error "failed to retrieve the version number from Steam repository"
	printf "\nDownloading steam-runtime version %s..\n" "$VERSION"
	mkdir -p "$RTARM64ROOT/pv-runtime"
	wget -q --show-progress -c -t 5 -O "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" "https://repo.steampowered.com/steamrt3c/images/${VERSION}/steam-runtime-steamrt-arm64.tar.xz" || exit_on_error "steam runtime download failed (check your internet connection)"
	tar -xf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" --directory "$RTARM64ROOT/pv-runtime" --checkpoint=200 --checkpoint-action=dot
	rm -rf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz"
fi

if [ ! -d "$STEAMROOT/Switchdeck/DXVK" ]; then
    printf "\nDownloading DXVK-Sarek..\n"
    mkdir -p "$STEAMROOT/Switchdeck/DXVK"

    LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
    DXVK_URL=$(echo "$LATEST_JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' | head -1)
    DXVK_TAG=$(echo "$LATEST_JSON" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)
    
    # protection fallback
    [ -z "$DXVK_URL" ] && { printf "\nError: GitHub API URL empty. Aborting installation.\n"; exit 1; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" "$DXVK_URL"
    tar -xzf "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" --directory "$STEAMROOT/Switchdeck/DXVK" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz"
    
    # Save version tag so the update script knows what's installed
    echo "$DXVK_TAG" > "$STEAMROOT/Switchdeck/dxvk-sarek_version.txt"
    printf "\nDXVK-Sarek installed successfully in Switchdeck/DXVK.\n"
fi

if [ ! -d "$STEAMROOT/Switchdeck/VKD3D" ]; then
    printf "\nDownloading VKD3D-Proton 2.3.1..\n"
    mkdir -p "$STEAMROOT/Switchdeck/VKD3D"

    VK_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.3.1/vkd3d-proton-2.3.1.tar.zst"

    # Check if zstd is missing
    command -v zstd >/dev/null || { printf "\nzstd is missing. Installing dependency.. (Requires sudo)\n"; [ -f /etc/fedora-release ] && sudo dnf install zstd -y || sudo apt install zstd -y; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" "$VK_URL"
    tar -xf "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" --directory "$STEAMROOT/Switchdeck/VKD3D" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst"
    
    printf "\nVKD3D installed successfully in Switchdeck/VKD3D.\n"
fi

if [ ! -d "$STEAMROOT/compatibilitytools.d/Proton 11.0-2e Armv8.0 (FEX)" ]; then
    printf "\nDownloading Proton 11.0-2e Armv8.0 (FEX)..\n"
    mkdir -p "$STEAMROOT/compatibilitytools.d"

    if wget -q --show-progress -c -t 5 -O "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz" "https://github.com/SildurFX/Switchdeck-Extras/releases/download/Proton-11.0-2e-Armv8.0/Proton.11.0-2e.Armv8.0.FEX.tar.gz"; then
        printf "\nExtracting files (this may take a moment)..\n"
        tar -xzf "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz" --directory "$STEAMROOT/compatibilitytools.d"
        rm -f "$STEAMROOT/compatibilitytools.d/Proton.11.0-2e.Armv8.0.FEX.tar.gz"
        touch "$STEAMROOT/Switchdeck/.fex_update2"
        printf "\nProton 11.0-2e Armv8.0 (FEX) successfully installed.\n"
    else
        printf "\nError: Failed to download Proton 11.0-2e Armv8.0 (FEX).\n"
        exit 1
    fi
fi

# Fix controller permissions
CONTROLLER_RELOAD=0
if command -v apt-get &>/dev/null; then
    dpkg -s steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo apt-get update && sudo apt-get install -y steam-devices && CONTROLLER_RELOAD=1
    }
elif command -v dnf &>/dev/null; then
    rpm -q steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo dnf install -y steam-devices && CONTROLLER_RELOAD=1
    }
elif command -v pacman &>/dev/null; then
    pacman -Qi steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo pacman -S --noconfirm steam-devices && CONTROLLER_RELOAD=1
    }
else
    if [ ! -f /etc/udev/rules.d/70-uinput.rules ]; then
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        printf "No supported package manager found. Configuring manually..\n"
        sudo sh -c "mkdir -p /etc/udev/rules.d && echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"' > /etc/udev/rules.d/70-uinput.rules"
        sudo modprobe uinput || true
        CONTROLLER_RELOAD=1
    fi
fi

if [ "$CONTROLLER_RELOAD" -eq 1 ]; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger --sysname-match=uinput 2>/dev/null || sudo udevadm trigger
    printf "\nController permissions applied successfully.\n"
fi

# Setup password rule for SD_SWAP and SD_ZRAM and optimize ZRAM config
SUDOERS_FILE="/etc/sudoers.d/switchdeck"
if [ ! -f "$SUDOERS_FILE" ]; then
    printf "\nSetting up permissions for SD_SWAP and SD_ZRAM.. (Requires sudo)\n"
    CURRENT_USER=$(whoami)
    RULE_LINE="$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/sbin/swapon, /usr/sbin/swapoff, /usr/sbin/zramctl, /usr/bin/dd, /usr/bin/chmod, /usr/sbin/mkswap"
    if ! sudo sh -c "echo \"$RULE_LINE\" > \"$SUDOERS_FILE\" && chown root:root \"$SUDOERS_FILE\" && chmod 0440 \"$SUDOERS_FILE\""; then
        printf "\nFailed to set up permissions for SD_SWAP and SD_ZRAM.\n"
    fi
    printf "\nOptimizing ZRAM Config.. (Requires sudo)\n"
    sudo mkdir -p /etc/sysctl.d
    sudo tee /etc/sysctl.d/99-zram.conf << 'EOF' >/dev/null
vm.swappiness=100
vm.page-cluster=0
EOF
    sudo sysctl --system >/dev/null 2>&1 || true
fi

if [ -x "$RTARM64ROOT/steam" ]; then
    printf "\nStarting Steam (Initial Update phase)..\n"
    export LD_LIBRARY_PATH="$RTARM64ROOT:${LD_LIBRARY_PATH-}"
    "$RTARM64ROOT/steam" "$@" || true
    
    printf "\nSteam exited. Downloading files to downgrade steam..\n"

    # temp dir for extraction
    TEMP_SD="$STEAMROOT/temp_sd"
    mkdir -p "$TEMP_SD"

	wget -q -t 5 -O- "https://github.com/SildurFX/Switchdeck/archive/refs/heads/main.tar.gz" | tar xz -C "$TEMP_SD" --strip-components=1 || exit_on_error "Failed to download/extract downgrade files"

    if [ -f "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" ]; then
        mkdir -p "$STEAMROOT/linuxarm64"
        tar -xzf "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" -C "$STEAMROOT/linuxarm64"
    fi

    if [ -f "$TEMP_SD/files/downgrade/linux_x86_64.zip" ]; then
        unzip -q -o "$TEMP_SD/files/downgrade/linux_x86_64.zip" -d "$STEAMROOT"
    fi

    if [ -f "$TEMP_SD/files/downgrade/steamui_websrc_all.zip" ]; then
        # Extract only the main folder entry
        unzip -q -o "$TEMP_SD/files/downgrade/steamui_websrc_all.zip" "steamui/*" -d "$STEAMROOT"
    fi
    
    # Reassemble and extract steamrtarm64
    if [ -f "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.partaa" ]; then
        mkdir -p "$STEAMROOT/steamrtarm64"
        cat "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.part"* > "$TEMP_SD/steamrtarm64.tar.gz"
        tar -xzf "$TEMP_SD/steamrtarm64.tar.gz" -C "$STEAMROOT/steamrtarm64"
        rm -f "$TEMP_SD/steamrtarm64.tar.gz"
    fi

    # move files and scripts
    cp -f  "$TEMP_SD/files/downgrade/steam.cfg" "$STEAMROOT/steam.cfg"
    cp -f  "$TEMP_SD/files/steam/launch-steam.sh" "$STEAMROOT/"
    cp -f  "$TEMP_SD/files/steam/update-switchdeck.sh" "$STEAMROOT/"

    # Cleanup
    rm -rf "$TEMP_SD"

    # Overkill but make sure everything is executable
	chmod -R +x "$STEAMROOT"

    # Setup
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

    DESKTOP_FILE="$MENU_DIR/steam.desktop"
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
    # Only deploy the right-click menu if the user is running KDE Plasma
    if [[ "${XDG_CURRENT_DESKTOP}" == *"KDE"* ]]; then
        KDE_MENU_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kio/servicemenus"
        [ -d "$HOME/.local/share/kservices5" ] && KDE_MENU_DIR="$HOME/.local/share/kservices5/ServiceMenus"
        mkdir -p "$KDE_MENU_DIR" "$STEAMROOT/Switchdeck"
        cat << EOF > "$STEAMROOT/Switchdeck/switchdeck-add-game"
#!/bin/sh
TARGET_ITEM="\$1"
[ -z "\$TARGET_ITEM" ] && exit 1
if ! ps ax | grep -q 'steamrtarm64/[s]team'; then
    kdialog --title Error --error "Require the Steam to be active."
    exit 1
fi
encodedUrl="steam://addnonsteamgame/\$(python3 -c "import urllib.parse; print(urllib.parse.quote(\\"\$TARGET_ITEM\\", safe=''))")"
touch /tmp/addnonsteamgamefile
xdg-open \$encodedUrl
bn=\$(basename "\$TARGET_ITEM")
kdialog --passivepopup "\$bn has been added to Steam." 5
EOF
        cat > "$KDE_MENU_DIR/addtosteam.desktop" <<EOF
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-executable;application/x-desktop;
Actions=addToSteam
X-KDE-Priority=TopLevel
Icon=$STEAMROOT/public/steam_tray_48.tga

[Desktop Action addToSteam]
Exec=$STEAMROOT/Switchdeck/switchdeck-add-game %f
Icon=$STEAMROOT/public/steam_tray_48.tga
Name=Add to Steam
EOF
        chmod +x "$STEAMROOT/Switchdeck/switchdeck-add-game" "$KDE_MENU_DIR/addtosteam.desktop"
    fi

    chmod +x "$DESKTOP_FILE"
    ln -fs "$DESKTOP_FILE" "$DESKTOP_DIR/steam.desktop"
    update-desktop-database "$MENU_DIR" 2>/dev/null

    # just to be safe
	chmod -R +x "$STEAMROOT"

    printf "\nInstallation complete!\n"
    printf "To launch Steam, use the provided desktop shortcuts\n"
    printf "or run launch-steam.sh in your Steam folder.\n\n"
    sleep 3
fi