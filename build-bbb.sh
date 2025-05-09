#!/bin/bash
# BeagleBone Black Yocto Build Script
# This script automates the setup and build process for BeagleBone Black

# Exit on any error
set -e

# Directory containing this script
SCRIPT_DIR="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logger function
log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for required packages
check_dependencies() {
    log "Checking dependencies..."
    local deps=(
        "git"
        "make"
        "gcc"
        "python3"
    )
    
    for dep in "${deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            error "$dep is required but not installed."
        fi
    done
}

# Initialize build environment
init_build_env() {
    log "Initializing build environment..."
    
    # Source Yocto environment if not already done
    if [ -z "$BUILDDIR" ]; then
        source poky/oe-init-build-env build
    fi
    
    # Return to script directory
    cd "$SCRIPT_DIR"
}

# Configure build
configure_build() {
    log "Configuring build for BeagleBone Black..."
    
    # Create/modify local.conf
    cat << 'EOF' > build/conf/local.conf
MACHINE = "beaglebone-black"
DISTRO = "poky"
PACKAGE_CLASSES = "package_rpm"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"

# Disk monitoring
BB_DISKMON_DIRS ??= "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    STOPTASKS,/tmp,100M,100K"

# Additional configurations
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
CONF_VERSION = "2"

# BeagleBone Black specific settings
KERNEL_DEVICETREE = "am335x-boneblack.dtb"
CORE_IMAGE_EXTRA_INSTALL += "kernel-modules"
CORE_IMAGE_EXTRA_INSTALL += "packagegroup-core-buildessential"

# Development tools
EXTRA_IMAGE_FEATURES += "tools-sdk"
EXTRA_IMAGE_FEATURES += "tools-debug"
EXTRA_IMAGE_FEATURES += "package-management"
EOF

    # Configure bblayers.conf
    cat << 'EOF' > build/conf/bblayers.conf
POKY_BBLAYERS_CONF_VERSION = "2"
BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ${TOPDIR}/../poky/meta \
  ${TOPDIR}/../poky/meta-poky \
  ${TOPDIR}/../poky/meta-yocto-bsp \
  ${TOPDIR}/../meta-openembedded/meta-oe \
  ${TOPDIR}/../meta-openembedded/meta-python \
  ${TOPDIR}/../meta-openembedded/meta-networking \
  ${TOPDIR}/../meta-arm \
  ${TOPDIR}/../meta-bbb \
  "
EOF
}

# Build the image
build_image() {
    log "Starting build process..."
    cd build
    bitbake core-image-bbb
}

# Main execution
main() {
    log "Starting BeagleBone Black build setup..."
    
    check_dependencies
    init_build_env
    configure_build
    
    log "Configuration complete. Starting build..."
    build_image
    
    log "Build process completed successfully!"
}

# Execute main function
main "$@"