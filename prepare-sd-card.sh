#!/usr/bin/env bash

if [[ $# -ne 3 ]]
    then
        echo "Usage ${0} sdCard path-to-loxone-harmony-integration.jar path-to-ssh-public-key"
        echo "e.g. ${0} /dev/mmcblk0 ./loxone-harmony-integration-all.jar ~alice/.ssh/id_rsa.pub"
        exit 1
fi

JAR_NAME=`basename "${2}"`
PUBLIC_KEY=`cat "${3}"`

# TODO unmount sd card first?

wget -qO- https://github.com/FooDeas/raspberrypi-ua-netinst/releases/download/v2.1.0/raspberrypi-ua-netinst-v2.1.0.img.xz | xzcat - > ${1}

MOUNT_POINT=`mktemp --directory`

mount -t vfat /dev/mmcblk0p1 "${MOUNT_POINT}"

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/installer-config.txt" <<- EOM
packages="openjdk-8-jre,iptables,openvpn"

username=pi
usersysgroups="systemd-journal"
user_ssh_pubkey="${PUBLIC_KEY}"
root_ssh_pwlogin=0
ssh_pwlogin=0

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

mkdir -p "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/etc/iptables"
cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/etc/iptables/rules.v4" <<- EOM
*nat
:PREROUTING ACCEPT [4:196]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
COMMIT

*filter
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
-A OUTPUT -o lo -j ACCEPT

-A INPUT -p icmp -m state --state NEW --icmp-type 8 -j ACCEPT
-A INPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -p icmp -j ACCEPT

-A INPUT -i eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 22 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state ESTABLISHED --sport 22 -j ACCEPT

-A INPUT -i eth0 -p udp -m state --state NEW,ESTABLISHED --dport 1194 -j ACCEPT
-A OUTPUT -o eth0 -p udp -m state --state ESTABLISHED --sport 1194 -j ACCEPT

-A INPUT -i eth0 -p udp -m state --state ESTABLISHED --sport 53 -j ACCEPT
-A OUTPUT -o eth0 -p udp -m state --state NEW,ESTABLISHED --dport 53 -j ACCEPT
-A INPUT -i eth0 -p tcp -m state --state ESTABLISHED --sport 53 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 53 -j ACCEPT

# Allow outbound HTTP and HTTPS requests
-A INPUT -i eth0 -p tcp -m state --state ESTABLISHED --sport 80 -j ACCEPT
-A INPUT -i eth0 -p tcp -m state --state ESTABLISHED --sport 443 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 80 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 443 -j ACCEPT

# Allow XMPP
-A INPUT -i eth0 -p tcp -m state --state ESTABLISHED --sport 5222 -j ACCEPT
-A INPUT -i eth0 -p tcp -m state --state ESTABLISHED --sport 5223 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 5222 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state NEW,ESTABLISHED --dport 5223 -j ACCEPT

# Allow inbound HTTP requests to loxone-harmony-integration web server
-A INPUT -i eth0 -p tcp -m state --state NEW,ESTABLISHED --sport 6789 -j ACCEPT
-A OUTPUT -o eth0 -p tcp -m state --state ESTABLISHED --dport 6789 -j ACCEPT

-A INPUT -i eth0 -p udp -m state --state ESTABLISHED --sport 123 -j ACCEPT
-A OUTPUT -o eth0 -p udp -m state --state NEW,ESTABLISHED --dport 123 -j ACCEPT

-A INPUT -i tun0 -j ACCEPT
-A FORWARD -i tun0 -j ACCEPT
-A OUTPUT -o tun0 -j ACCEPT

-A FORWARD -i tun0 -o eth0 -s 10.8.0.0/24 -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

-A INPUT -m limit --limit 3/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 4
-A FORWARD -m limit --limit 3/min -j LOG --log-prefix "iptables_FORWARD_denied: " --log-level 4
-A OUTPUT -m limit --limit 3/min -j LOG --log-prefix "iptables_OUTPUT_denied: " --log-level 4

-A INPUT -j REJECT
-A FORWARD -j REJECT
-A OUTPUT -j REJECT

COMMIT
EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/root/etc/iptables/rules.v6" <<- EOM
*filter

-A INPUT -j REJECT
-A FORWARD -j REJECT
-A OUTPUT -j REJECT

COMMIT
EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/files/systemd.list" <<- EOM
root:root 444 /opt/loxone-harmony-integration/${JAR_NAME}
root:root 644 /lib/systemd/system/loxone-harmony-integration.service
root:root 644 /etc/iptables/rules.v4
root:root 644 /etc/iptables/rules.v6
EOM

cat > "${MOUNT_POINT}/raspberrypi-ua-netinst/config/post-install.txt" <<- EOM
chroot /rootfs adduser --system --no-create-home systemd-loxone
mkdir -p /etc/systemd/system/
ln -s /lib/systemd/system/loxone-harmony-integration.service /etc/systemd/system/loxone-harmony-integration.service
chroot /rootfs systemctl enable loxone-harmony-integration

chroot /rootfs apt-get -y update
echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | chroot /rootfs debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | chroot /rootfs debconf-set-selections
chroot /rootfs apt-get -y install iptables-persistent

echo "net.ipv4.ip_forward=1" >> /rootfs/etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /rootfs/etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /rootfs/etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /rootfs/etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /rootfs/etc/sysctl.d/99-sysctl.conf

chroot /rootfs sysctl -p

chroot /rootfs adduser --system --no-create-home systemd-openvpn

EOM

umount "${MOUNT_POINT}"
rmdir "${MOUNT_POINT}"