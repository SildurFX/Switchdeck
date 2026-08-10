# Switchdeck: Steam ARM64 for Switch (L4T)

<img src="https://i.imgur.com/h0VFbgW.png" width="100%" alt="Steam Deck UI">

<div align="center">
  <img src="https://i.imgur.com/zaBCMSh.png" width="49%" alt="In-Game">
  <img src="https://i.imgur.com/b5L16Dc.png" width="49%" alt="Settings">
</div>

---

## Installation
1. Download and run `install-steam.sh` in your **terminal**.
2. Use the shortcut or `launch-steam.sh` in your Steam folder to launch Steam. On first launch a popup will appear and install steam runtime 4.0 arm64.
3. In Steam go to **Settings** -> **Library** and turn on: Low Bandwidth, Low Performance and Disable Community Content.
4. Go to **Settings** -> **Compatibility** and select Proton Experimental or Proton 11.0-1 Armv8.0 (FEX). **FEX does not support 32-bit games** because of severe graphical bugs.
5. Go to **Settings** -> **Controller:** -> **Show Advanced Settings:** Enable "Combine Joycon Pairs" and Enable Steam Input for Pro and Generic Controller. ([Capture Button](https://wiki.switchroot.org/wiki/~gitbook/image?url=https%3A%2F%2F1282083284-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F5A2PNyzG80QTDoltbtvZ%252Fuploads%252Fgit-blob-3f3536275b42d0474793e7cf4be05e666d5c8394%252Fjoycon_mapping.png%3Falt%3Dmedia&width=768&dpr=3&quality=100&sign=2c313375&sv=2) below D-Pad switches from Desktop Mode to Controller)
6. Restart Steam to apply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek), [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) and Vertex Explosion patch to Proton.

**Note:** If Steam updates your Proton version you have to relaunch it to reapply the [DXVK-Sarek,](https://github.com/pythonlover02/DXVK-Sarek) [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) and Vertex Explosion patch. It's applied on launch.

---

## Requirements
* [Linux for Switch:](https://wiki.switchroot.org/wiki/linux) Kubuntu Noble or Fedora 42. **Make sure to install all the latest system updates.** (Fedora 42 is currently unstable on some systems)
* [Box64](https://github.com/ptitseb/box64) to run games. Shipped with Fedora 42 by default. Switchdeck installs it for you on Ubuntu.
* **Vulkan 1.2 Support:** Fedora ships with the latest GPU driver. Switchdeck updates it for you on Ubuntu.
* [RAM OC:](https://wiki.switchroot.org/wiki/linux/linux-features#ram_oc0) Nintendo Switch has 4GB shared between CPU and GPU so overclocking RAM helps a lot.

---

## Features
* `SD_GAMEMODE=1 or 2 %command%` Games launched with this command unload the steamwebhelper to **free up over 1GB of RAM.** In mode 2 it also unloads KDE services including Network services. Restoring Steam or KDE after game exit is gonna take a few seconds.
* `SD_SWAP=1 %command%` Adds 4GB of Swap for the current game and disables it on exit. Required for some games that run out of RAM.
* `SD_ZRAM=1 or 2 %command%` Adds 1GB or 2GB of extra ZRAM for the current game and disables it on exit. Provides better stability for games close to the RAM limit.
* [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* [VKD3D v2.3.1](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* Vulkan extension patch for Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom) to fix Vertex explosions in 32-bit games. (Caused by broken Nvidia Drivers.)
* KDE Context Menu: Add to Steam, to easily import non-Steam games.

---

## Information
* [Game compatibility list](https://docs.google.com/spreadsheets/d/1UrLwRaIZGAL6J7l9QK_DO4MB45KzIUKIfKZIOE4hid4). Not every title is supported or fully playable.
* Use the square [taskbar icon](https://drive.google.com/file/d/1ciiL1fqIvq2lNtDRZEdrBAeOh0wa03Ds/view?usp=sharing) to change your [OC Profile](https://wiki.switchroot.org/wiki/linux/linux-features#power-profiles-all-models). OC CPU should be enough for most games.
* Several launch commands are defined in `launch-steam.sh`. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* `wineesync` causes crashes with DXVK and is disabled in `launch-steam.sh`.
* [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases), [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom) and [Luxtorpeda](https://luxtorpeda.org/) are supported. Some games may only work with [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* [ProtonPlus](https://github.com/Vysp3r/ProtonPlus) can be used to install custom Proton versions. Just download and run the latest [aarch64 appimage](https://github.com/Vysp3r/ProtonPlus/releases).
* FEX currently does not support 32-bit games because of severe graphical bugs. Use non-FEX Proton versions like Experimental for 32-bit games.

---

## Explanation
This script automates the download and installation of Steam ARM64. Because Steam client builds newer than April 15th, 2026, cause "illegal instruction" crashes on the Nintendo Switch, the script automatically downgrades specific parts of Steam to that version. The L4T kernel (4.9) is technically too old to support FEX-Emu but a WIP Proton FEX build for Armv8.0 is available [here](https://github.com/SildurFX/Switchdeck-Extras/releases/tag/Proton-11.0-1-Armv8.0). This setup also establishes an alternative x86_64 environment powered by Box64 to run x86_64 Proton builds. It applies custom compatibility patches to both native Proton and GE-Proton to ensure Vulkan 1.2 support and to disable a broken Vulkan extension, directly resolving vertex explosion bugs in 32-bit games on the Tegra X1.

*Credits to Ivy for the original steam-arm64 download script*

---

## Community & Support

* **[My Discord](https://discord.gg/EbsAecrVXg)** – My Discord for all my mods and projects.
* **[Twitter](https://x.com/SildurFX)** – Updates, clips, and general progress.
* **[Switchroot Discord](https://discord.gg/53mtKYt)** – For general L4T Linux help.
* **[Patreon](https://www.patreon.com/Sildur)** / **[PayPal](https://www.paypal.com/donate?token=_2027BoQI-5DqpHvI-Du7HX8MHdXJ5_vQ05_Owto9XiM8x3j76yxS1nevrBbpn5UV2yJfymQNmTsMPw6&locale.x=US)** – If you'd like to support my work!

---

### Legal Notice
The bash scripts (`launch-steam.sh`, etc.) in this repository are provided under the **GNU General Public License v3.0 (GPL-3.0)**.
The Steam binaries, libraries, and resources located in `/files/downgrade/` are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.
