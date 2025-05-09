# BeagleBone Black Yocto Development Guide

This guide provides industry-standard steps for setting up a Yocto-based development environment for BeagleBone Black.

## Prerequisites

1. **Host System Requirements**
   - Ubuntu 20.04 or newer (recommended)
   - Minimum 8GB RAM (16GB recommended)
   - 100GB free disk space
   - Required packages:
     ```bash
     sudo apt-get install gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
     iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint \
     xterm python3-subunit mesa-common-dev zstd liblz4-tool
     ```

2. **Development Tools**
   - Cross-compiler toolchain
   - SD card writer (e.g., balenaEtcher)
   - Serial console (e.g., minicom)

## Project Structure

```
bbb-yocto-project/
├── build/
├── meta-bbb/              # BeagleBone Black specific layer
│   ├── conf/
│   │   ├── layer.conf
│   │   └── machine/
│   │       └── beaglebone-black.conf
│   ├── recipes-bsp/
│   │   └── u-boot/
│   ├── recipes-kernel/
│   │   └── linux/
│   └── recipes-custom/    # Your custom applications
├── poky/                  # Core Yocto
├── meta-openembedded/    # Additional layers
├── meta-arm/             # ARM architecture support
├── build.sh              # Build script
└── flash-bbb.sh         # Flashing script
```

## Initial Setup

1. **Create Project Directory**
   ```bash
   mkdir bbb-yocto-project
   cd bbb-yocto-project
   ```

2. **Clone Required Repositories**
   ```bash
   git clone -b kirkstone git://git.yoctoproject.org/poky
   git clone -b kirkstone git://git.openembedded.org/meta-openembedded
   git clone -b kirkstone git://git.yoctoproject.org/meta-arm
   ```

3. **Create Custom Layer**
   ```bash
   source poky/oe-init-build-env build
   bitbake-layers create-layer ../meta-bbb
   ```

## BeagleBone Black Configuration

1. **Machine Configuration** (meta-bbb/conf/machine/beaglebone-black.conf)
   ```bitbake
   #@TYPE: Machine
   #@NAME: BeagleBone Black machine
   #@DESCRIPTION: Machine configuration for BeagleBone Black

   require conf/machine/include/ti-soc.inc
   SOC_FAMILY:append = ":am335x"

   KERNEL_DEVICETREE = "am335x-boneblack.dtb"
   PREFERRED_PROVIDER_virtual/kernel = "linux-bbb"
   PREFERRED_PROVIDER_virtual/bootloader = "u-boot-bbb"

   UBOOT_MACHINE = "am335x_boneblack_config"
   UBOOT_ENTRYPOINT = "0x80008000"
   UBOOT_LOADADDRESS = "0x80008000"

   MACHINE_FEATURES = "usbgadget usbhost vfat alsa"

   IMAGE_FSTYPES += "tar.xz wic.xz"
   WKS_FILE ?= "beaglebone-black.wks"
   ```

## Build Script (build.sh)

Create an automated build script:

```bash
#!/bin/bash
# Initialize build environment and build BeagleBone Black image build

# Setup build environment
source poky/oe-init-build-env build

# Configure local.conf
cat << EOF >> conf/local.conf
MACHINE = "beaglebone-black"
DISTRO = "poky"
PACKAGE_CLASSES = "package_rpm"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
BB_DISKMON_DIRS ??= "\\
    STOPTASKS,${TMPDIR},1G,100K \\
    STOPTASKS,${DL_DIR},1G,100K \\
    STOPTASKS,${SSTATE_DIR},1G,100K \\
    STOPTASKS,/tmp,100M,100K"
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
CONF_VERSION = "2"
EOF

# Add layers
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-arm
bitbake-layers add-layer ../meta-bbb

# Build the image
bitbake core-image-bbb
```

## Custom Image Recipe

Create a custom image recipe (meta-bbb/recipes-core/images/core-image-bbb.bb):

```bitbake
require recipes-core/images/core-image-base.bb

SUMMARY = "Custom BeagleBone Black image"

IMAGE_FEATURES += " \\
    debug-tweaks \\
    package-management \\
    ssh-server-dropbear \\
    tools-debug \\
    tools-sdk \\
"

CORE_IMAGE_EXTRA_INSTALL += " \\
    packagegroup-core-buildessential \\
    kernel-modules \\
    linux-firmware \\
    i2c-tools \\
    openssh \\
    minicom \\
    vim \\
"
```

## Building the Image

1. **Setup Environment**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

2. **Build Process**
   - First build may take several hours
   - Subsequent builds use shared state cache
   - Image will be in build/tmp/deploy/images/beaglebone-black/

## Flashing to SD Card

Create flash-bbb.sh:

```bash
#!/bin/bash
# Flash BeagleBone Black image to SD card

if [ $# -ne 1 ]; then
    echo "Usage: $0 <device>"
    echo "Example: $0 /dev/sdb"
    exit 1
fi

DEVICE=$1
IMAGE="build/tmp/deploy/images/beaglebone-black/core-image-bbb-beaglebone-black.wic.xz"

if [ ! -e "$IMAGE" ]; then
    echo "Image file not found: $IMAGE"
    exit 1
fi

echo "Flashing $IMAGE to $DEVICE..."
xzcat "$IMAGE" | sudo dd of="$DEVICE" bs=4M status=progress
sync

echo "Flashing complete!"
```

## Development Workflow

1. **Create Custom Layer**
   ```bash
   bitbake-layers create-layer meta-custom
   ```

2. **Add Custom Recipes**
   - Place recipes in appropriate categories
   - Update layer.conf dependencies
   - Add layer to build configuration

3. **Build and Test**
   ```bash
   bitbake core-image-bbb
   ```

4. **Flash and Debug**
   ```bash
   ./flash-bbb.sh /dev/sdX
   ```

## Debugging

1. **Serial Console**
   ```bash
   minicom -D /dev/ttyUSB0 -b 115200
   ```

2. **Network Debug**
   - SSH available on port 22
   - Root access enabled for development

3. **Build Issues**
   - Check tmp/work/ for build logs
   - Use bitbake -e to examine variables

## Best Practices

1. **Version Control**
   - Keep meta-bbb layer in version control
   - Use tags for releases
   - Document all machine-specific configurations

2. **Security**
   - Disable debug features in production
   - Remove development tools from production images
   - Use proper key management

3. **Testing**
   - Create automated test suite
   - Test both build and runtime
   - Validate all custom recipes

## Maintenance

1. **Regular Updates**
   - Update base layers (poky, meta-openembedded)
   - Check for security patches
   - Maintain compatibility with upstream

2. **Documentation**
   - Document all custom modifications
   - Maintain build and flash instructions
   - Keep README updated

## Additional Resources

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [BeagleBone Black System Reference Manual](https://github.com/beagleboard/beaglebone-black/wiki/System-Reference-Manual)
- [OpenEmbedded Layer Index](https://layers.openembedded.org/)
