#!/bin/sh

case "$1" in
    start)
        echo "Loading misc-modules"
        cd /lib/modules/$(uname -r)/extra/
        /usr/bin/module_load hello
        /usr/bin/module_load faulty
        ;;
    stop)
        /usr/bin/module_unload faulty
        /usr/bin/module_unload hello
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac

exit 0
