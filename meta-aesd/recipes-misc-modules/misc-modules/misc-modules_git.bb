LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit module update-rc.d

SRC_URI = "git://git@github.com/cu-ecen-aeld/assignment-7-Ekpenyong-Esu.git;protocol=ssh;branch=main \
           file://S98lddmodules.sh"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

INITSCRIPT_NAME = "S98lddmodules"
INITSCRIPT_PARAMS = "start 98 5 . stop 20 0 1 6 ."

EXTRA_OEMAKE += "KERNELDIR=${STAGING_KERNEL_DIR}"

RPROVIDES:${PN} += "kernel-module-hello"
RPROVIDES:${PN} += "kernel-module-faulty"

do_compile() {
    oe_runmake -C ${S}/misc-modules KERNELDIR=${STAGING_KERNEL_DIR}
}

do_install() {
    # Install kernel modules
    install -d ${D}${base_libdir}/modules/${KERNEL_VERSION}/extra
    install -m 0644 ${S}/misc-modules/hello.ko ${D}${base_libdir}/modules/${KERNEL_VERSION}/extra/
    install -m 0644 ${S}/misc-modules/faulty.ko ${D}${base_libdir}/modules/${KERNEL_VERSION}/extra/

    # Install module scripts in /usr/bin
    install -d ${D}${bindir}
    install -m 0755 ${S}/misc-modules/module_load ${D}${bindir}/
    install -m 0755 ${S}/misc-modules/module_unload ${D}${bindir}/

    # Install init script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/S98lddmodules.sh ${D}${sysconfdir}/init.d/S98lddmodules
}

FILES:${PN} += "${base_libdir}/modules/${KERNEL_VERSION}/extra/*.ko"
FILES:${PN} += "${bindir}/*"
FILES:${PN} += "${sysconfdir}/init.d/S98lddmodules"

KERNEL_MODULE_AUTOLOAD += "hello faulty"
