#!/bin/sh

# verbose
#export PS4='${LINENO}: '
#set -x

"$PRESSURE_VESSEL_RUNTIME_BASE/pressure-vessel/bin/steam-runtime-launch-client" \
    --pass-env-matching=STEAM* \
    --pass-env-matching=Steam* \
    --pass-env-matching=STEAM_COMPAT_* \
    --pass-env-matching=ENABLE_* \
    --pass-env-matching=BOX64_* \
    --pass-env-matching=WINE* \
    --pass-env-matching=PROTON_* \
    --pass-env-matching=__GL_* \
    --pass-env-matching=STAGING_* \
    --pass-env-matching=VKD3D_* \
    --pass-env-matching=DXVK_* \
    --pass-env=LD_PRELOAD \
    --pass-env=ENABLE_VK_LAYER_VALVE_steam_overlay_1 \
    --bus-name=com.steampowered.PressureVessel.LaunchAlongsideSwitchdeck \
    -- "$@"