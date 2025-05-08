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

The build script (`build.sh`) is a crucial component that automates the setup and build process. Here's how to create it:

1. **Basic Script Structure**
   ```bash
   #!/bin/bash
   ```
   - Create build.sh in the root directory
   - Make it executable with `chmod +x build.sh`

2. **Git Submodule Management**
   - Initialize and update submodules for Poky and other dependencies
   - This ensures all required Yocto components are present

3. **Build Environment Setup**
   - Source the Poky build environment
   - This creates the build directory and configuration files

4. **Machine Configuration**
   - Set QEMU ARM64 as target machine
   - Configure local.conf automatically

5. **Layer Management**
   - Add meta-aesd layer to the build
   - Verify layer integration

6. **Build Process**
   - Trigger bitbake to build the custom image
   - Handle errors appropriately

## Creating the meta-aesd Layer

The meta-aesd layer is a crucial component that contains custom recipes and configurations for the AESD project. Here's how to create it from scratch:

1. **Create Layer Structure**
   ```
   meta-aesd/
   ├── conf/
   │   ├── layer.conf          # Layer configuration
   │   └── machine/            # Machine-specific configurations
   ├── recipes-aesd-assignments/
   │   └── aesd-assignments/   # Custom application recipes
   │       ├── aesd-assignments_git.bb
   │       └── files/         # Patches and additional files
   ├── recipes-misc-modules/   # Kernel module recipes
   │   └── misc-modules/
   │       ├── misc-modules_git.bb
   │       └── files/
   └── recipes-scull/         # Scull driver recipes
       └── scull/
           ├── scull_git.bb
           └── files/
   ```

2. **Create Layer Configuration**
   Create conf/layer.conf with:
   ```bitbake
   # We have a conf and classes directory, add to BBPATH
   BBPATH .= ":${LAYERDIR}"

   # We have recipes-* directories, add to BBFILES
   BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
               ${LAYERDIR}/recipes-*/*/*.bbappend"

   BBFILE_COLLECTIONS += "meta-aesd"
   BBFILE_PATTERN_meta-aesd = "^${LAYERDIR}/"
   BBFILE_PRIORITY_meta-aesd = "6"

   LAYERSERIES_COMPAT_meta-aesd = "hardknott kirkstone"
   ```

3. **Create Recipe Structure**
   - **AESD Assignments Recipe**: Contains main application build instructions
   - **Misc Modules Recipe**: Kernel module build configurations
   - **Scull Driver Recipe**: Driver-specific build instructions

4. **Layer Integration Steps**
   a. **Initialize Layer**:
      - Create base directories and configuration files
      - Set up recipe hierarchies
   
   b. **Configure Dependencies**:
      - Add dependencies in layer.conf
      - Configure machine-specific settings
   
   c. **Create Base Recipes**:
      - Add core recipes for AESD applications
      - Configure build and installation steps

5. **Layer Testing**
   - Test layer integration
   - Verify recipe builds
   - Validate configurations

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
