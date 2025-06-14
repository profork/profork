#!/bin/bash

# Detect system architecture
ARCH=$(uname -m)

# If the system is ARM64 (aarch64), execute the ARM script
if [ "$ARCH" = "aarch64" ]; then
    echo "ARM64 (aarch64) detected. Running the ARM setup script..."
    sleep 2
    curl -L https://github.com/profork/profork/raw/master/mame2010_v41%2B/2010_arm64.sh | bash
    exit 0
fi

# If the system is x86_64, continue with the normal setup
if [ "$ARCH" != "x86_64" ]; then
    echo "This script only runs on x86_64 (AMD/Intel) or aarch64 (ARM64)."
    exit 1
fi
echo "x86_64 (AMD/INTEL) detected. Running x86_64 setup script....."
sleep 2

echo "This script will restore MAME 2010 (.0139) to Batocera v41 (and should work on newer builds too)"
echo "A separate MAME 0139 system will be added adjacent to MAME"

sleep 5

# MAME 0.139 Setup and Installation Script for Batocera
# This script installs the required MAME 2010 files, places them in the correct directory,
# and ensures symlinks are managed via pro-custom.sh.

# Define URLs for required files
ES_CFG_URL="https://raw.githubusercontent.com/profork/profork/master/mame2010_v41%2B/es_systems_mame0139.cfg"
INFO_FILE_URL="https://github.com/profork/profork/releases/download/r1/mame0139_libretro.info"
CORE_FILE_URL="https://github.com/profork/profork/releases/download/r1/mame0139_libretro.so"
CORE_FILE_2010_URL="https://github.com/profork/profork/releases/download/r1/mame2010_libretro.so"

# Define paths
BASE_DIR="/userdata/system/pro/mame2010"
EXTRA_DIR="$BASE_DIR/extra"
STARTUP_SCRIPT="$EXTRA_DIR/startup"
CUSTOM_SH="/userdata/system/custom.sh"
PRO_CUSTOM_SH="/userdata/system/pro-custom.sh"
ES_CFG_PATH="/userdata/system/configs/emulationstation/es_systems_mame0139.cfg"
INFO_DEST="$BASE_DIR/mame0139_libretro.info"
CORE_DEST="$BASE_DIR/mame0139_libretro.so"
CORE_2010_DEST="$BASE_DIR/mame2010_libretro.so"

# Ensure required directories exist
mkdir -p "$EXTRA_DIR"

# Download necessary files
echo "Downloading necessary files..."
wget -O "$ES_CFG_PATH" "$ES_CFG_URL" || { echo "Failed to download $ES_CFG_URL"; exit 1; }
wget -O "$INFO_DEST" "$INFO_FILE_URL" || { echo "Failed to download $INFO_FILE_URL"; exit 1; }
wget -O "$CORE_DEST" "$CORE_FILE_URL" || { echo "Failed to download $CORE_FILE_URL"; exit 1; }
wget -O "$CORE_2010_DEST" "$CORE_FILE_2010_URL" || { echo "Failed to download $CORE_2010_URL"; exit 1; }

# Set correct permissions
chmod 644 "$ES_CFG_PATH" "$INFO_DEST"
chmod 755 "$CORE_DEST" "$CORE_2010_DEST"



# Write the startup script dynamically
echo "#!/usr/bin/env bash" > "$STARTUP_SCRIPT"
echo "ln -sf $INFO_DEST /usr/share/libretro/info/mame0139_libretro.info" >> "$STARTUP_SCRIPT"
echo "ln -sf $CORE_DEST /usr/lib/libretro/mame0139_libretro.so" >> "$STARTUP_SCRIPT"
echo "ln -sf $CORE_2010_DEST /usr/lib/libretro/mame2010_libretro.so" >> "$STARTUP_SCRIPT"

# Ask user if they want to symlink ROMs
dialog --yesno "Do you want to link your existing /userdata/roms/mame folder to mame0139?\n\nYes: Link existing ROMs\nNo: Keep separate mame0139 folder" 12 60
if [ $? -eq 0 ]; then
    mkdir -p /userdata/roms/mame0139
    echo "ln -sf /userdata/roms/mame /userdata/roms/mame0139" >> "$STARTUP_SCRIPT"
else
    mkdir -p /userdata/roms/mame0139
fi
# Make the startup script executable
chmod +x "$STARTUP_SCRIPT"

# Ensure pro-custom.sh includes the startup script
echo "Ensuring pro-custom.sh includes the startup script..."
if ! grep -q "$STARTUP_SCRIPT" "$PRO_CUSTOM_SH" 2>/dev/null; then
    echo "bash $STARTUP_SCRIPT &" >> "$PRO_CUSTOM_SH"
    chmod +x "$PRO_CUSTOM_SH"
fi

# Ensure custom.sh exists and includes pro-custom.sh
echo "Ensuring custom.sh exists and includes pro-custom.sh..."
if [ ! -f "$CUSTOM_SH" ]; then
    echo "#!/bin/bash" > "$CUSTOM_SH"
    echo "bash $PRO_CUSTOM_SH &" >> "$CUSTOM_SH"
    chmod +x "$CUSTOM_SH"
elif ! grep -q "$PRO_CUSTOM_SH" "$CUSTOM_SH"; then
    echo "bash $PRO_CUSTOM_SH &" >> "$CUSTOM_SH"
    chmod +x "$CUSTOM_SH"
fi


dialog --title "Install Done" --msgbox "Setup complete! MAME 0.139 is installed, and the MAME 2010 startup script will run at next boot.\n\nPlease reboot Batocera for changes to take effect.\n\nAfter rebooting, update gamelists." 10 60
