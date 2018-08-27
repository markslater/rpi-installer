#!/usr/bin/env bash

if [[ $# -ne 2 ]]
    then
        echo "Usage ${0} sdCard path-to-loxone-harmony-integration.jar"
        echo "e.g. ${0} /dev/mmcblk0 ./loxone-harmony-integration-all.jar"
        exit 1
fi

# TODO unmount sd card first?

wget -qO- https://github.com/debian-pi/raspbian-ua-netinst/releases/download/v1.0.9/raspbian-ua-netinst-v1.0.9.img.xz | xzcat - > ${1}
#wget https://github.com/FooDeas/raspberrypi-ua-netinst/releases/download/v2.2.1/raspberrypi-ua-netinst-v2.2.1.img.xz
#xzcat raspberrypi-ua-netinst-v2.2.1.img.xz > ${1}

#echo "packages=openjdk-8-jre-headless" > /media/mark/7CAE-BF6A/installer-config.txt
#echo "packages=openjdk-8-jre-headless" > /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/installer-config.txt

#mkdir -p /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/
#cp "${2}" /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/files/root/opt/loxone-harmony-integration/
#
#mkdir -p /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/
#cat > /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/files/root/lib/systemd/system/loxone-harmony-integration.service <<- EOM
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
#
#cat > /media/mark/7CAE-BF6A/raspberrypi-ua-netinst/config/post-install.txt <<- EOM
#ln -s /lib/systemd/system/loxone-harmony-integration.service /etc/systemd/system/loxone-harmony-integration.service
#sysctl enable loxone-harmony-integration
#sysctl start loxone-harmony-integration
#EOM