#!/bin/sh

case "$1" in
    start)
        echo "Loading misc-modules"
        # Load hello module first
        /sbin/insmod /lib/modules/$(uname -r)/extra/hello.ko || exit 1
        # Then load faulty module
        /sbin/insmod /lib/modules/$(uname -r)/extra/faulty.ko || exit 1
        ;;
    stop)
        echo "Unloading misc-modules"
        # Unload in reverse order
        /sbin/rmmod faulty || exit 1
        /sbin/rmmod hello || exit 1
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac

exit 0
