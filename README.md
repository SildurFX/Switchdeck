# Switchdeck: Steam ARM64 for Switch (L4T)

---

## Installation
1. Download and run `install-steam.sh` in your **terminal**.
2. Download the latest [Proton-CachyOS x86_64 release](https://github.com/CachyOS/proton-cachyos/releases) and unpack it into:  
   `~/.local/share/Steam/compatibilitytools.d/`
3. Copy `runtime-helper.sh` and `toolmanifest.vdf` from `/Steam/compatibilitytools.d/` into your new `proton-cachyos-x86_64` folder (overwrite when prompted).
4. Restart Steam, go to **Settings** -> **Compatibility**, and select **Proton-CachyOS**.
5. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

---

## Information
*  You **must** install [box64](https://github.com/ptitseb/box64) to run games.
*  Some games may require OpenGL to boot. Use this launch option:  
   `PROTON_USE_WINED3D=1 %command%`
*  `steam-boot.sh` contains several launch commands at the top. Feel free to tweak them to fit your needs.

*Credits to Ivy for the original steam-arm64 script*

---

### Legal Notice
The bash scripts (`launch-steam.sh`, `steam-boot.sh`, etc.) in this repository are provided under the **MIT License**.
The Steam binaries, libraries, and resources located in `/files/downgrade/` are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.

