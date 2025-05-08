#!/bin/sh

case "$1" in
    start)
        echo "Loading scull module"
        cd /lib/modules/$(uname -r)/extra && /usr/bin/scull_load
        ;;
    stop)
        echo "Unloading scull module"
        /usr/bin/scull_unload
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac

exit 0
