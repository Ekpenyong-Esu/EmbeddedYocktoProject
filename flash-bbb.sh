#!/bin/bash
# Script to flash BeagleBone Black image to SD card or eMMC
# Author: Your Name
# Date: May 8, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logger functions
log() {
    echo -e "${GREEN}[FLASH]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
fi

# Parse arguments
usage() {
    echo "Usage: $0 [-d device] [-t type]"
    echo "  -d device: Target device (e.g., /dev/sdb)"
    echo "  -t type: Flash type (sd or emmc)"
    echo "Example: $0 -d /dev/sdb -t sd"
    exit 1
}

DEVICE=""
FLASH_TYPE=""

while getopts "d:t:h" opt; do
    case ${opt} in
        d )
            DEVICE=$OPTARG
            ;;
        t )
            FLASH_TYPE=$OPTARG
            ;;
        h )
            usage
            ;;
        \? )
            usage
            ;;
    esac
done

if [ -z "$DEVICE" ] || [ -z "$FLASH_TYPE" ]; then
    usage
fi

# Validate device
if [ ! -b "$DEVICE" ]; then
    error "Device $DEVICE does not exist or is not a block device"
fi

# Validate flash type
if [ "$FLASH_TYPE" != "sd" ] && [ "$FLASH_TYPE" != "emmc" ]; then
    error "Flash type must be 'sd' or 'emmc'"
fi

# Check for mounted partitions
if mount | grep "$DEVICE" > /dev/null; then
    warn "Device $DEVICE has mounted partitions. Unmounting..."
    umount ${DEVICE}* 2>/dev/null || true
fi

# Set image path based on build directory
IMAGE_DIR="build/tmp/deploy/images/beaglebone-black"
if [ "$FLASH_TYPE" = "sd" ]; then
    IMAGE="${IMAGE_DIR}/core-image-bbb-beaglebone-black.wic.xz"
else
    IMAGE="${IMAGE_DIR}/core-image-bbb-beaglebone-black.emmc.xz"
fi

# Check if image exists
if [ ! -f "$IMAGE" ]; then
    error "Image file not found: $IMAGE"
fi

# Flash the image
log "Flashing image to $DEVICE..."
log "This will take several minutes. Do not remove the device."

xzcat "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
sync

log "Flashing complete!"
log "You can now safely remove the device"

# Additional steps for eMMC
if [ "$FLASH_TYPE" = "emmc" ]; then
    log "For eMMC flashing:"
    log "1. Insert SD card into powered-off BeagleBone Black"
    log "2. Hold boot button while applying power"
    log "3. Release boot button after a few seconds"
    log "4. Wait for flashing to complete (all LEDs will be solid)"
fi

exit 0
