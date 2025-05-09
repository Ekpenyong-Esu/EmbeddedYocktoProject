#!/bin/bash

# Exit on error
set -e

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Cleaning Yocto build artifacts..."

# Clean build artifacts but preserve configuration
if [ -d "${SCRIPT_DIR}/build" ]; then
    # Source the Yocto environment
    source poky/oe-init-build-env build

    # Clean sstate-cache
    echo "Cleaning sstate-cache..."
    bitbake -c cleansstate core-image-aesd

    # Clean tmp directory
    echo "Cleaning tmp directory..."
    rm -rf tmp/*

    # Clean downloads that are already unpacked
    echo "Cleaning unpacked downloads..."
    bitbake -c cleanall core-image-aesd
else
    echo "Build directory not found. Nothing to clean."
fi

echo "Cleanup complete!"