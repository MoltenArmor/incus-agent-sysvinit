#!/bin/sh
set -ue

[ -x /etc/init.d/incus-agent ] && [ -x /lib/init/incus-agent-setup ] && exit 0

if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'Please run as root!'
    exit 127
fi

mount_cdrom() {
    mount "/dev/disk/by-id/scsi-0QEMU_QEMU_CD-ROM_incus_agent" "$1" > /dev/null 2>&1
}

mount_9p() {
    modprobe 9pnet_virtio > /dev/null 2>&1 || true
    mount -t 9p config "$1" -o access=0,trans=virtio,size=1048576 > /dev/null 2>&1
}

install_sysvinit_files() {
    chown 0:0 incus-agent.sh
    chmod 755 incus-agent.sh
    cp -f incus-agent.sh /etc/init.d/incus-agent
    mkdir /mnt/.incus-agent
    mount_9p /mnt/.incus-agent || mount_cdrom /mnt/.incus-agent || return 1
    cp -f /mnt/.incus-agent/systemd/incus-agent-setup /lib/init/
    insserv -v incus-agent
}

if (grep -qF "sysvinit" /sbin/init); then
    install_sysvinit_files || true
    umount -l /mnt/.incus-agent && rmdir /mnt/.incus-agent
else
    echo "Unsupported init system!"
fi

echo ""
echo "Incus agent has been installed, reboot to confirm setup."

