# Switchdeck: Steam ARM64 for Switch (L4T)

<img src="https://i.imgur.com/h0VFbgW.png" width="100%" alt="Steam Deck UI">

<div align="center">
  <img src="https://i.imgur.com/zaBCMSh.png" width="49%" alt="In-Game">
  <img src="https://i.imgur.com/b5L16Dc.png" width="49%" alt="Settings">
</div>

---

## Installation
1. Download and run `install-steam.sh` in your **terminal**.
2. In Steam go to **Settings** -> **Library** and turn on: Low Bandwidth, Low Performance and Disable Community Content.
3. Go to **Settings** -> **Compatibility** and select either Proton 10, 11 or Experimental. You can also download them manually in your library.
4. Restart Steam to apply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) patch to your Proton version. It's applied on launch.
5. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

**Note:** If Steam updates your Proton version you have to relaunch it to reapply the DXVK-Sarek patch.

---

## Requirements
* [Linux for Switch](https://wiki.switchroot.org/wiki/linux)
* [Box64](https://github.com/ptitseb/box64) to run games. Shipped with fedora 42 by default, install from this [repo](https://github.com/ryanfortner/box64-debs) for ubuntu.

---

## Information
* [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases) can be used instead of Valve-Proton, it comes with [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek)
* `update-switch.sh` can be used to update all switchdeck scripts and parts of the steam client.
* `launch-steam.sh` contains several launch commands. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* `wineesync` is force-disabled in `launch-steam.sh` because it causes crashes with dxvk / vulkan.
* If a game crashes on launch or has broken graphics (mostly 32 bit games) use opengl instead: `PROTON_USE_WINED3D=1 %command%`.
* For older games, you may need to force Proton 10+ in the settings, as Steam often defaults to unsupported older versions.
* `launch-steamRT3.sh` can be used to run Steam in a container (RT3 Beta). For this to work, your Proton installation must be patched: Copy `runtime-helper.sh` and `toolmanifest.vdf` from your `compatibilitytools.d` folder into your Proton folder.

---

## Explanation
This script downloads and installs the latest Steam ARM64 version.
Builds newer than April 15th, 2026, do not work on the Nintendo Switch, so this script will automatically downgrade parts of the client to that version to prevent "illegal instruction" crashes.
The L4T kernel 4.9 is too old to use FEX-Emu, instead this script sets up an x86_64 runtime container (SteamRT3) to use with Proton x86_64 and box64.

*Credits to Ivy for the original steam-arm64 download script*

---

## Community & Support

* **[My Discord](https://discord.gg/EbsAecrVXg)** – My Discord for all my mods and projects.
* **[Twitter](https://x.com/SildurFX)** – Updates, clips, and general progress.
* **[Switchroot Discord](https://discord.gg/53mtKYt)** – For general L4T Linux help.
* **[Patreon](https://www.patreon.com/Sildur)** / **[PayPal](https://www.paypal.com/donate?token=_2027BoQI-5DqpHvI-Du7HX8MHdXJ5_vQ05_Owto9XiM8x3j76yxS1nevrBbpn5UV2yJfymQNmTsMPw6&locale.x=US)** – If you'd like to support my work!

---

### Legal Notice
The bash scripts (`launch-steam.sh`, `launch-steamRT3.sh`, etc.) in this repository are provided under the **MIT License**.
The Steam binaries, libraries, and resources located in `/files/downgrade/` are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.
