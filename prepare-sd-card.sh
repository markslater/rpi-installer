#!/usr/bin/env bash

if [[ $# -ne 2 ]]
    then
        echo "Usage ${0} sdCard path-to-loxone-harmony-integration.jar"
        echo "e.g. ${0} /dev/mmcblk0 ./loxone-harmony-integration-all.jar"
        exit 1
fi

# TODO unmount sd card first?

wget -qO- https://github.com/FooDeas/raspberrypi-ua-netinst/releases/download/v1.5.2/raspberrypi-ua-netinst-v1.5.2.img.xz | xzcat - > ${1}

MOUNT_POINT=`mktemp --directory`

mount -t vfat /dev/mmcblk0p1 "${MOUNT_POINT}"

echo "packages=openjdk-8-jre-headless" > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/installer-config.txt"

#mkdir -p /media/mark/74F9-234A/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/
#cp "${2}" /media/mark/74F9-234A/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/
#
#mkdir -p /media/mark/74F9-234A/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/
#cat > /media/mark/74F9-234A/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/loxone-harmony-integration.service <<- EOM
#[Unit]
#Description=Loxone/Harmony Hub integration service
#After=network-online.target
#
#[Service]
#SyslogIdentifier=LoxoneHarmony
#ExecStart=/usr/bin/java -jar /opt/loxone-harmony-integration/loxone-harmony-integration-all.jar
#SuccessExitStatus=143
#
#
#[Install]
#WantedBy=multi-user.target
#EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/post-install.txt" <<- EOM
#ln -s /lib/systemd/system/loxone-harmony-integration.service /etc/systemd/system/loxone-harmony-integration.service
systemctl enable loxone-harmony-integration
systemctl start loxone-harmony-integration
EOM

umount "${MOUNT_POINT}"
rmdir "${MOUNT_POINT}"