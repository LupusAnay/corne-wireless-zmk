#!/bin/bash

set -e

echo

# Function to flash a half
flash_half() {
    local HALF=$1
    local FIRMWARE_PATH=$2
    
    echo "📱 Ready to flash $HALF half"
    echo "1. Put $HALF keyboard half in bootloader mode (double-tap reset)"
    echo "2. Wait for it to mount as USB drive"
    read -p "Press Enter when ready..."
    
    local TIMEOUT=60
    local COUNT=0
    local MOUNT_PATH=""
    
    while [ $COUNT -lt $TIMEOUT ]; do
        # Check common mount locations on Arch Linux
        MOUNT_PATH=$(find /media /mnt /run/media/$USER 2>/dev/null \
            -maxdepth 2 -type d \( \
            -iname "*nicenano*" -o \
            -iname "*nrf52*" -o \
            -iname "*bootloader*" -o \
            -iname "*circuitpy*" -o \
            -iname "*rpi*" \
            \) | head -1)
        
        # Also check /dev for the device directly (alternative method)
        if [ -z "$MOUNT_PATH" ]; then
            # Check if nRF52840 bootloader device exists
            if [ -e "/dev/ttyACM0" ] || ls /dev/ttyACM* 1>/dev/null 2>&1; then
                echo "Found nRF52 device, waiting for mount..."
            fi
        fi
        
        if [ -n "$MOUNT_PATH" ]; then
            echo "Found mounted device: $MOUNT_PATH"
            
            if [ ! -f "$FIRMWARE_PATH" ]; then
                echo "❌ Firmware file not found: $FIRMWARE_PATH"
                exit 1
            fi
            
            echo "Copying $FIRMWARE_PATH to $MOUNT_PATH"
            cp "$FIRMWARE_PATH" "$MOUNT_PATH/"
            sync
            
            # Verify copy succeeded
            sleep 2
            if [ ! -d "$MOUNT_PATH" ] || [ ! -f "$MOUNT_PATH/zmk.uf2" ]; then
                echo "✅ $HALF half flashed successfully!"
                break
            else
                echo "Device still mounted, waiting for unmount..."
                sleep 2
            fi
        else
            echo "Waiting for device to mount... ($COUNT/$TIMEOUT)"
            sleep 2
            COUNT=$((COUNT + 1))
        fi
    done
    
    if [ $COUNT -ge $TIMEOUT ]; then
        echo "❌ Timeout waiting for $HALF half"
        exit 1
    fi
    echo
}

# Detect user for /run/media path
if [ -z "$USER" ]; then
    USER=$(whoami)
fi

# Flash both halves
flash_half "LEFT" "build/left/zephyr/zmk.uf2"
flash_half "RIGHT" "build/right/zephyr/zmk.uf2"

echo "🎉 Both halves flashed successfully!"
echo "Your keyboard should be ready to use."
