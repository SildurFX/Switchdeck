# Switchdeck: Steam ARM64 for Switch (L4T)
**Branch Info:** Latest steam client on Armv8.0 with [LSE emulation](https://github.com/SildurFX/LSE-Emu).   
**Work in progress, box64 and 32-bit games are currently not supported.**

<img src="https://i.imgur.com/h0VFbgW.png" width="100%" alt="Steam Deck UI">

<div align="center">
  <img src="https://i.imgur.com/zaBCMSh.png" width="49%" alt="In-Game">
  <img src="https://i.imgur.com/b5L16Dc.png" width="49%" alt="Settings">
</div>

---

## Installation
1. Download `install-steam.sh` from this repo and run it in your **terminal**.
2. Use the shortcut or `launch-steam.sh` in your Steam folder to launch Steam.
3. In Steam go to **Settings** -> **Interface** and turn on: Enable GPU accelerated rendering. Then go to **Library** and enable: Low Bandwidth, Low Performance and Disable Community Content.
4. Go to **Settings** -> **Compatibility** and select: Proton 11.0-2e Armv8.0 (FEX). **FEX does not support 32-bit games** because of severe graphical bugs.
5. Go to **Settings** -> **Controller:** -> **Show Advanced Settings:** Enable "Combine Joycon Pairs" and Enable Steam Input for Pro and Generic Controller. ([Capture Button](https://wiki.switchroot.org/wiki/~gitbook/image?url=https%3A%2F%2F1282083284-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F5A2PNyzG80QTDoltbtvZ%252Fuploads%252Fgit-blob-3f3536275b42d0474793e7cf4be05e666d5c8394%252Fjoycon_mapping.png%3Falt%3Dmedia&width=768&dpr=3&quality=100&sign=2c313375&sv=2) below D-Pad switches from Desktop Mode to Controller)
6. Restart Steam to apply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) patch.

**Note:** If Steam updates your Proton version you have to relaunch it to reapply the [DXVK-Sarek,](https://github.com/pythonlover02/DXVK-Sarek) [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) patch. It's applied on launch.

---

## Requirements
* Games must be launched with: `LD_PRELOAD="/usr/local/lib/liblse_emu.so" %command%`. Work in progress, without it the emulator doesn't load correctly into steams runtime.
* [Linux for Switch:](https://wiki.switchroot.org/wiki/linux) Kubuntu Noble or Fedora 44. **Make sure to install all the latest system updates.**
* [Box64](https://github.com/ptitseb/box64) to run games. Switchdeck installs it for you on Ubuntu and Fedora.
* **Vulkan 1.2 Support:** Fedora ships with the latest GPU driver. Switchdeck updates it for you on Ubuntu.
* [RAM OC:](https://wiki.switchroot.org/wiki/linux/linux-features#ram_oc0) Nintendo Switch has 4GB shared between CPU and GPU so overclocking RAM helps a lot.

---

## Features
* `SD_GAMEMODE=1 or 2 %command%` Games launched with this command unload the steamwebhelper to **free up over 1GB of RAM.** In mode 2 it also unloads KDE services including Network services. Restoring Steam or KDE after game exit is gonna take a few seconds.
* `SD_SWAP=1 %command%` Adds 4GB of Swap for the current game and disables it on exit. Required for some games that run out of RAM.
* `SD_ZRAM=1 or 2 %command%` Adds 1GB or 2GB of extra ZRAM for the current game and disables it on exit. Provides better stability for games close to the RAM limit.
* [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* [VKD3D v2.3.1](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* KDE Context Menu: Add to Steam, to easily import non-Steam games.

---

## Information
* [Game compatibility list](https://docs.google.com/spreadsheets/d/1UrLwRaIZGAL6J7l9QK_DO4MB45KzIUKIfKZIOE4hid4). Not every title is supported or fully playable.
* Use the square [taskbar icon](https://drive.google.com/file/d/1ciiL1fqIvq2lNtDRZEdrBAeOh0wa03Ds/view?usp=sharing) to change your [OC Profile](https://wiki.switchroot.org/wiki/linux/linux-features#power-profiles-all-models). OC CPU should be enough for most games.
* Several launch commands are defined in `launch-steam.sh`. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* `wineesync` causes crashes with DXVK and is disabled in `launch-steam.sh`. `FSync` is currently only supported on Fedora 44.
* FEX currently does not support 32-bit games because of severe graphical bugs.

---

## Explanation
This script automates the download and installation of Steam ARM64. Because Steam client builds newer than April 15th, 2026, cause "illegal instruction" crashes on Armv8.0, this script automatically installs an [LSE-Emulator](https://github.com/SildurFX/LSE-Emu) to emulate and patch the missing Armv8.1 instructions that Steam requires.

---

## Community & Support

* **[My Discord](https://discord.gg/EbsAecrVXg)** – My Discord for all my mods and projects.
* **[Twitter](https://x.com/SildurFX)** – Updates, clips, and general progress.
* **[Switchroot Discord](https://discord.gg/53mtKYt)** – For general L4T Linux help.
* **[Patreon](https://www.patreon.com/Sildur)** / **[PayPal](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=KY99R4D8YUEX2&source=url&ssrt=1786589479049)** – If you'd like to support my work!

---

### Legal Notice
The bash scripts (`launch-steam.sh`, etc.) in this repository are provided under the **GNU General Public License v3.0 (GPL-3.0)**.
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.
