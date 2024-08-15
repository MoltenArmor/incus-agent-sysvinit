#!/bin/sh

### BEGIN INIT INFO
# Short-Description:    Incus agent daemon
# Description:          Incus agent daemon
# Provides:             incus-agent
# Required-Start:       $remote_fs
# Required-Stop:        $remote_fs
# Default-Start:        S
# Default-Stop:
### END INIT INFO

set -ue

SETUP_SCRIPT=/usr/local/bin/incus-agent-setup
DAEMON=/run/incus_agent/incus-agent
NAME=incus-agent
PIDFILE=/run/incus_agent/incus-agent.pid
WORKDIR=/run/incus_agent

. /lib/lsb/init-functions

# Exit if incus-agent can not be found.
[ -x "${SETUP_SCRIPT}" ] || [ -x "${DAEMON}" ] || exit 0

# Exit if VSock does not exist.
if !  [ -e "/dev/virtio-ports/org.linuxcontainers.incus" ]; then
    if ! [ -e "/dev/virtio-ports/org.linuxcontainers.lxd" ]; then
        exit 0
    fi
fi

case "$1" in
    start)
        $SETUP_SCRIPT
        start-stop-daemon --start --quiet --oknodo --background --exec "$DAEMON" --pidfile "$PIDFILE" --make-pidfile --chdir "$WORKDIR" -- "$@"
        ;;
    stop)
        killproc -p "$PIDFILE" "$DAEMON"
        ;;
    status)
        status_of_proc -p "$PIDFILE" "$DAEMON" "$NAME"
        ;;
    restart|reload|force-reload)
        stop
        start
        ;;
    *)
        printf '%s\n' "Usage: $0 {start|stop|restart|force-reload}" 1>&2
        exit 1
        ;;
esac

exit 0

