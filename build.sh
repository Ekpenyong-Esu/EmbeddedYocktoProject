#!/bin/bash
# Script to build image for qemu.
# Author: Siddhant Jajoo.

# Step 1: Initialize and update git submodules
git submodule init
git submodule sync
git submodule update

# Step 2: Setup Yocto build environment
source poky/oe-init-build-env

# Step 3: Configure machine type for QEMU ARM64
CONFLINE="MACHINE = \"qemuarm64\""

# Check and update local.conf if needed
cat conf/local.conf | grep "${CONFLINE}" > /dev/null
local_conf_info=$?

if [ $local_conf_info -ne 0 ];then
    echo "Append ${CONFLINE} in the local.conf file"
    echo ${CONFLINE} >> conf/local.conf
else
    echo "${CONFLINE} already exists in the local.conf file"
fi

# Step 4: Add meta-aesd layer if not present
bitbake-layers show-layers | grep "meta-aesd" > /dev/null
layer_info=$?

if [ $layer_info -ne 0 ];then
    echo "Adding meta-aesd layer"
    bitbake-layers add-layer ../meta-aesd
else
    echo "meta-aesd layer already exists"
fi

# Step 5: Build the image
set -e
bitbake core-image-aesd
