# Switchdeck: Steam ARM64 for Switch (L4T)

---

## Installation
1. Download and run `install-steam.sh` in your **terminal**.
2. Download [Proton-CachyOS x86_64](https://github.com/CachyOS/proton-cachyos/releases) (recommended [build](https://github.com/CachyOS/proton-cachyos/releases/tag/cachyos-10.0-20260424-slr)) and unpack it into:  
   `~/.local/share/Steam/compatibilitytools.d/`
3. Restart Steam, go to **Settings** -> **Compatibility**, and select **Proton-CachyOS**.
4. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

**Note:** `update-switch.sh` can be used to update all switchdeck scripts and parts of the steam client.
`launch-steamRT3.sh` can be used to run Steam in a container (RT3 Beta). For this to work, your Proton installation must be patched:
Copy `runtime-helper.sh` and `toolmanifest.vdf` from your `compatibilitytools.d` folder into your Proton folder.

---

## Information
*  You **must** install [box64](https://github.com/ptitseb/box64) to run games.
*  [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases) is recommended because it comes bundled with [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and the Switch only supports Vulkan 1.2.
*  `launch-steam.sh` contains several launch commands at the top. Feel free to tweak them to fit your needs.
*  `launch-steamRT3.sh` is optional because some games may not boot correctly inside the runtime container.
*  `wineesync` is force-disabled in `launch-steam.sh` because it causes crashes with dxvk / vulkan.
*   If a game crashes on launch or has broken graphics (mostly 32 bit games) use opengl instead: `PROTON_USE_WINED3D=1 %command%`.

---

## Explanation
This script downloads and installs the latest Steam ARM64 version.
Builds newer than April 15th, 2026, do not work on the Nintendo Switch, so this script will automatically downgrade parts of the client to that version to prevent "illegal instruction" crashes.
The L4T kernel 4.9 is too old to use FEX-Emu, instead this script sets up an x86_64 runtime container (SteamRT3) to use with Proton x86_64 and box64.

*Credits to Ivy for the original steam-arm64 script*

---

### Legal Notice
The bash scripts (`launch-steam.sh`, `launch-steamRT3.sh`, etc.) in this repository are provided under the **MIT License**.
The Steam binaries, libraries, and resources located in `/files/downgrade/` are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.

