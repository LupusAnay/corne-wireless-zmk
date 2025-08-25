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
    while [ $COUNT -lt $TIMEOUT ]; do
        MOUNT_PATH=$(ls /Volumes/ 2>/dev/null | grep -i "nicenano\|rpi\|bootloader\|circuitpy" | head -1)
        if [ -n "$MOUNT_PATH" ]; then
            echo "Found mounted device: $MOUNT_PATH"
            # Check if firmware file exists
            if [ ! -f "$FIRMWARE_PATH" ]; then
                echo "❌ Firmware file not found: $FIRMWARE_PATH"
                exit 1
            fi
            
            # Simple copy - macOS often reports errors even when flash succeeds
            echo "Copying $FIRMWARE_PATH to /Volumes/$MOUNT_PATH"
            cp "$FIRMWARE_PATH" "/Volumes/$MOUNT_PATH/" 2>/dev/null || true
            sync
            sleep 2
            
            # Check if device disappeared (successful flash)
            if [ ! -d "/Volumes/$MOUNT_PATH" ]; then
                echo "✅ $HALF half flashed successfully!"
                break
            else
                echo "Retrying flash..."
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

# Flash both halves
flash_half "LEFT" "build/left/zephyr/zmk.uf2"
flash_half "RIGHT" "build/right/zephyr/zmk.uf2"

echo "🎉 Both halves flashed successfully!"
echo "Your keyboard should be ready to use."