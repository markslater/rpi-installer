#!/usr/bin/env bash

if [[ $# -ne 2 ]]
    then
        echo "Usage ${0} sdCard path-to-loxone-harmony-integration.jar"
        echo "e.g. ${0} /dev/mmcblk0 ./loxone-harmony-integration-all.jar"
        exit 1
fi

JAR_NAME=`basename $2`

# TODO unmount sd card first?

wget -qO- https://github.com/FooDeas/raspberrypi-ua-netinst/releases/download/v2.1.0/raspberrypi-ua-netinst-v2.1.0.img.xz | xzcat - > ${1}

MOUNT_POINT=`mktemp --directory`

mount -t vfat /dev/mmcblk0p1 "${MOUNT_POINT}"

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/installer-config.txt" <<- EOM
packages="openjdk-8-jre"

username=pi
userpw=raspberry
usersysgroups="systemd-journal"

hostname=pi

timezone=Europe/London
keyboard_layout=gb
locales="en_GB.UTF-8"
system_default_locale="en_GB.UTF-8"
EOM


mkdir -p "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/"
cp "${2}" "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/"

mkdir -p "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/"
cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/loxone-harmony-integration.service" <<- EOM
[Unit]
Description=Loxone/Harmony Hub integration service
After=network-online.target

[Service]
User=systemd-loxone
SyslogIdentifier=LoxoneHarmony
ExecStart=/usr/bin/java -jar /opt/loxone-harmony-integration/${JAR_NAME}
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/systemd.list" <<- EOM
root:root 444 /opt/loxone-harmony-integration/${JAR_NAME}
root:root 644 /lib/systemd/system/loxone-harmony-integration.service
EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/post-install.txt" <<- EOM
chroot /rootfs adduser --system --no-create-home systemd-loxone
mkdir -p /etc/systemd/system/
ln -s /lib/systemd/system/loxone-harmony-integration.service /etc/systemd/system/loxone-harmony-integration.service
chroot /rootfs systemctl enable loxone-harmony-integration
EOM

umount "${MOUNT_POINT}"
rmdir "${MOUNT_POINT}"