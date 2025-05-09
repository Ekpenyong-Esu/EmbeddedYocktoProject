# AESD Yocto Project Setup Guide

This repository contains the base setup for AESD (Advanced Embedded Software Development) Yocto assignments. Follow these instructions to set up and build the project.

## Prerequisites

Before starting, ensure you have the following installed on your Linux system:
- Git
- Python 3.8+
- Essential build tools (make, gcc, etc.)
- Required packages for Yocto:
  ```bash
  sudo apt-get install gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint \
  xterm python3-subunit mesa-common-dev zstd liblz4-tool
  ```

## Creating the Build Script

The build script (`build.sh`) is a crucial component that automates the setup and build process. Here's the complete implementation:

1. **Create and Open build.sh**
   ```bash
   touch build.sh
   chmod +x build.sh
   ```

2. **Complete build.sh Implementation**
   Add the following content to build.sh:
   ```bash
   #!/bin/bash
   # Script to build AESD Yocto image
   
   # Exit on error
   set -e
   
   # Directory containing this script
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   
   # Initialize and update Poky submodule if needed
   if [ ! -d "${SCRIPT_DIR}/poky" ]; then
       git submodule init
       git submodule update
   fi
   
   # Source Yocto environment setup script
   source poky/oe-init-build-env build
   
   # Add meta-aesd layer to bblayers.conf if not already present
   if ! grep -q "meta-aesd" conf/bblayers.conf; then
       bitbake-layers add-layer ../meta-aesd
   fi
   
   # Configure MACHINE in local.conf if not already set
   if ! grep -q "^MACHINE = \"qemuarm64\"" conf/local.conf; then
       echo 'MACHINE = "qemuarm64"' >> conf/local.conf
   fi
   
   # Add any additional configurations needed
   if ! grep -q "CORE_IMAGE_EXTRA_INSTALL" conf/local.conf; then
       echo 'CORE_IMAGE_EXTRA_INSTALL += "aesd-assignments"' >> conf/local.conf
       echo 'CORE_IMAGE_EXTRA_INSTALL += "openssh"' >> conf/local.conf
   fi
   
   # Build the image
   bitbake core-image-aesd
   ```

## Creating the meta-aesd Layer

Let's create the meta-aesd layer with a complete step-by-step guide:

1. **Create Base Directory Structure**
   ```bash
   mkdir -p meta-aesd/conf
   mkdir -p meta-aesd/recipes-aesd-assignments/aesd-assignments
   mkdir -p meta-aesd/recipes-aesd-assignments/images
   mkdir -p meta-aesd/recipes-misc-modules/misc-modules
   mkdir -p meta-aesd/recipes-scull/scull
   ```

2. **Create Layer Configuration (meta-aesd/conf/layer.conf)**
   Create the file with:
   ```bitbake
   # We have a conf and classes directory, add to BBPATH
   BBPATH .= ":${LAYERDIR}"
   
   # We have recipes-* directories, add to BBFILES
   BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
               ${LAYERDIR}/recipes-*/*/*.bbappend"
   
   BBFILE_COLLECTIONS += "meta-aesd"
   BBFILE_PATTERN_meta-aesd = "^${LAYERDIR}/"
   BBFILE_PRIORITY_meta-aesd = "6"
   
   LAYERDEPENDS_meta-aesd = "core"
   LAYERSERIES_COMPAT_meta-aesd = "kirkstone"
   ```

3. **Create Core Image Recipe (meta-aesd/recipes-aesd-assignments/images/core-image-aesd.bb)**
   ```bitbake
   SUMMARY = "A custom image for AESD assignments"
   DESCRIPTION = "A custom image containing AESD assignment components"
   
   inherit core-image
   inherit extrausers
   
   CORE_IMAGE_EXTRA_INSTALL += "aesd-assignments"
   CORE_IMAGE_EXTRA_INSTALL += "openssh"
   
   # Configure root password for development (not for production)
   PASSWD = "\$5\$2WoxjAdaC2\$l4aj6Is.EWkD72Vt.byhM5qRtF9HcCM/5YpbxpmvNB5"
   EXTRA_USERS_PARAMS = "usermod -p '${PASSWD}' root;"
   
   # Install kernel modules
   IMAGE_INSTALL:append = " scull misc-modules"
   ```

4. **Create AESD Assignments Recipe (meta-aesd/recipes-aesd-assignments/aesd-assignments/aesd-assignments_git.bb)**
   ```bitbake
   SUMMARY = "AESD assignments"
   LICENSE = "MIT"
   LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
   
   # Replace with your actual repository URL
   SRC_URI = "git://git@github.com/your-username/your-repo.git;protocol=ssh;branch=master"
   
   PV = "1.0+git${SRCPV}"
   SRCREV = "${AUTOREV}"
   
   S = "${WORKDIR}/git/server"
   
   inherit update-rc.d
   
   INITSCRIPT_PACKAGES = "${PN}"
   INITSCRIPT_NAME:${PN} = "aesdsocket-start-stop.sh"
   
   FILES:${PN} += "${bindir}/aesdsocket"
   FILES:${PN} += "${sysconfdir}/init.d/aesdsocket-start-stop.sh"
   
   TARGET_LDFLAGS += "-pthread -lrt"
   
   do_configure () {
       :
   }
   
   do_compile () {
       oe_runmake
   }
   
   do_install () {
       install -d ${D}${bindir}
       install -m 0755 ${S}/aesdsocket ${D}${bindir}/
       
       install -d ${D}${sysconfdir}/init.d
       install -m 0755 ${S}/aesdsocket-start-stop.sh ${D}${sysconfdir}/init.d/
   }
   ```

5. **Create Misc Modules Recipe (meta-aesd/recipes-misc-modules/misc-modules/misc-modules_git.bb)**
   ```bitbake
   inherit module
   
   SUMMARY = "Miscellaneous kernel modules for AESD assignments"
   LICENSE = "MIT"
   LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
   
   # Replace with your actual repository URL
   SRC_URI = "git://git@github.com/your-username/your-repo.git;protocol=ssh;branch=master"
   
   PV = "1.0+git${SRCPV}"
   SRCREV = "${AUTOREV}"
   
   S = "${WORKDIR}/git/misc-modules"
   
   EXTRA_OEMAKE:append:task-install = " -C ${STAGING_KERNEL_DIR} M=${S}"
   EXTRA_OEMAKE += "KERNELDIR=${STAGING_KERNEL_DIR}"
   
   inherit kernel-module-split
   ```

6. **Create Scull Driver Recipe (meta-aesd/recipes-scull/scull/scull_git.bb)**
   ```bitbake
   inherit module
   
   SUMMARY = "Scull driver for AESD assignments"
   LICENSE = "MIT"
   LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
   
   # Replace with your actual repository URL
   SRC_URI = "git://git@github.com/your-username/your-repo.git;protocol=ssh;branch=master"
   
   PV = "1.0+git${SRCPV}"
   SRCREV = "${AUTOREV}"
   
   S = "${WORKDIR}/git/scull"
   
   EXTRA_OEMAKE:append:task-install = " -C ${STAGING_KERNEL_DIR} M=${S}"
   EXTRA_OEMAKE += "KERNELDIR=${STAGING_KERNEL_DIR}"
   
   inherit kernel-module-split
   ```

## Layer Integration with Yocto

The meta-aesd layer integrates with Yocto in several ways:

1. **Build System Integration**
   - Layer automatically added by build.sh
   - Configured in bblayers.conf
   - Recipes accessible to bitbake

2. **Recipe Organization**
   ```
   meta-aesd/
   ├── recipes-aesd-assignments/   # Application recipes
   │   └── aesd-assignments/
   │       ├── aesd-assignments_git.bb    # Main recipe
   │       └── files/                     # Support files
   ├── recipes-misc-modules/      # Kernel modules
   └── recipes-scull/            # Driver components
   ```

3. **Configuration Management**
   - Layer priority set in layer.conf
   - Machine configurations in conf/machine/
   - Recipe-specific configurations in recipe directories

4. **Build Process Integration**
   - Layer automatically detected by build system
   - Recipes available for image inclusion
   - Dependencies managed through layer configuration

## Layer Development Workflow

1. **Initial Setup**
   ```bash
   mkdir -p meta-aesd/conf
   mkdir -p meta-aesd/recipes-aesd-assignments/aesd-assignments
   mkdir -p meta-aesd/recipes-misc-modules/misc-modules
   mkdir -p meta-aesd/recipes-scull/scull
   ```

2. **Recipe Development**
   - Create base recipes
   - Add necessary patches
   - Configure build options
   - Set up installation paths

3. **Testing and Validation**
   - Test recipe builds
   - Verify layer integration
   - Validate configurations
   - Test in QEMU

4. **Maintenance**
   - Update recipes as needed
   - Manage dependencies
   - Keep configurations current

## Layer Dependencies

The meta-aesd layer depends on:
- poky (core)
- meta-poky
- meta-yocto-bsp

## Using the Layer

1. **Automatic Integration**
   - The build script automatically integrates the layer
   - No manual configuration needed for basic usage

2. **Manual Integration**
   ```bash
   bitbake-layers add-layer ../meta-aesd
   ```

3. **Verification**
   ```bash
   bitbake-layers show-layers
   ```

## Project Setup Steps

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd assignment-6-Ekpenyong-Esu
   ```

2. **Initialize Poky**
   - The repository includes the Poky reference distribution
   - Initialize the build environment:
   ```bash
   source poky/oe-init-build-env
   ```
   This command will:
   - Set up the build environment
   - Create the build directory if it doesn't exist
   - Change to the build directory

3. **Configure the Build**
   - The meta-aesd layer contains custom recipes and configurations
   - Ensure the meta-aesd layer is included in your bblayers.conf
   - Key configuration files are in:
     - `conf/local.conf`: Local build configurations
     - `conf/bblayers.conf`: Layer configurations

4. **Building the Image**
   - Use the build script:
   ```bash
   ./build.sh
   ```
   - This will initiate the Yocto build process
   - The first build may take several hours depending on your system

5. **Running in QEMU**
   - After successful build, run the image in QEMU:
   ```bash
   ./runqemu.sh
   ```

## Project Structure

The project is organized as follows:
```
project_root/
├── meta-aesd/               # Custom layer for AESD
│   ├── conf/               # Layer configuration
│   ├── recipes-aesd-assignments/
│   ├── recipes-misc-modules/
│   └── recipes-scull/
├── poky/                   # Yocto reference distribution
├── build/                  # Build output directory
│   ├── conf/              # Build configuration
│   ├── tmp/              # Build artifacts
│   └── downloads/        # Downloaded sources
├── build.sh               # Main build script
└── runqemu.sh            # QEMU launch script
```

## Creating Core Recipes

1. **Main Image Recipe** (recipes-aesd-assignments/images/core-image-aesd.bb)
   ```bitbake
   inherit core-image
   CORE_IMAGE_EXTRA_INSTALL += "aesd-assignments"
   CORE_IMAGE_EXTRA_INSTALL += "openssh"
   inherit extrausers
   
   # Configure root password for development (not for production)
   PASSWD = "\$5\$2WoxjAdaC2\$l4aj6Is.EWkD72Vt.byhM5qRtF9HcCM/5YpbxpmvNB5"
   EXTRA_USERS_PARAMS = "usermod -p '${PASSWD}' root;"
   
   # Install kernel modules
   IMAGE_INSTALL:append = " scull misc-modules"
   ```

2. **AESD Assignments Recipe** (recipes-aesd-assignments/aesd-assignments/aesd-assignments_git.bb)
   ```bitbake
   LICENSE = "MIT"
   LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
   
   SRC_URI = "git://git@github.com/your-username/your-repo.git;protocol=ssh;branch=master"
   
   PV = "1.0+git${SRCPV}"
   SRCREV = "${AUTOREV}"  # Use specific commit hash in production
   
   S = "${WORKDIR}/git/server"
   
   FILES:${PN} += "${bindir}/aesdsocket ${bindir}/aesdsocket-start-stop.sh"
   TARGET_LDFLAGS += "-pthread -lrt"
   
   do_install () {
       install -d ${D}${bindir}
       install -m 0755 ${S}/aesdsocket ${D}${bindir}
       install -m 0755 ${S}/aesdsocket-start-stop.sh ${D}${bindir}
   }
   ```

3. **Kernel Module Recipes**
   
   Create in recipes-misc-modules/misc-modules/misc-modules_git.bb:
   ```bitbake
   inherit module
   
   DESCRIPTION = "Miscellaneous kernel modules"
   LICENSE = "MIT"
   
   SRC_URI = "git://github.com/your-username/your-repo.git;protocol=ssh;branch=master"
   
   S = "${WORKDIR}/git/misc-modules"
   
   inherit kernel-module-split
   ```

## Recipe Dependencies

Configure recipe dependencies in your layer's conf/layer.conf:

```bitbake
LAYERDEPENDS_meta-aesd = "core"
LAYERDEPENDS_meta-aesd += "openembedded-layer"
```

## Building Specific Recipes

To test individual recipes during development:

1. **Build AESD Assignments**
   ```bash
   bitbake aesd-assignments
   ```

2. **Build Kernel Modules**
   ```bash
   bitbake misc-modules
   bitbake scull
   ```

3. **Build Complete Image**
   ```bash
   bitbake core-image-aesd
   ```

## Recipe Debugging

1. **View Recipe Tasks**
   ```bash
   bitbake -c listtasks recipe-name
   ```

2. **Clean Recipe**
   ```bash
   bitbake -c clean recipe-name
   ```

3. **Force Rebuild**
   ```bash
   bitbake -f -c compile recipe-name
   ```

## Running Tests

- Use the test script to validate your implementation:
```bash
./test.sh
```

## Cleaning the Build

To clean the build environment:
```bash
./clean.sh
```

## Troubleshooting

Common issues and solutions:

1. **Build Environment Issues**
   - Ensure all prerequisites are installed
   - Check Yocto version compatibility
   - Verify Python version

2. **Layer Problems**
   - Verify layer configuration in bblayers.conf
   - Check layer dependencies
   - Ensure proper layer priority

3. **Build Failures**
   - Check build logs in tmp/log/
   - Verify network connectivity
   - Ensure sufficient disk space

## Additional Resources

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [BitBake Manual](https://docs.yoctoproject.org/bitbake.html)
- [Yocto Project Quick Build Guide](https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html)
