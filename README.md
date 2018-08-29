# rpi-installer
Unattended install for Raspberry Pi

## raspbian-ua-netinst-v1.0.9 output

```bash
root@pi:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev             10M     0   10M   0% /dev
tmpfs            36M  4.3M   32M  12% /run
/dev/mmcblk0p2   15G  589M   14G   5% /
tmpfs            90M     0   90M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs            90M     0   90M   0% /sys/fs/cgroup
tmpfs            90M   32K   90M   1% /tmp
/dev/mmcblk0p1  122M   56M   67M  46% /boot
tmpfs            18M     0   18M   0% /run/user/0
```

```bash
root@pi:~# cat /proc/cpuinfo
processor	: 0
model name	: ARMv6-compatible processor rev 7 (v6l)
BogoMIPS	: 697.95
Features	: half thumb fastmult vfp edsp java tls 
CPU implementer	: 0x41
CPU architecture: 7
CPU variant	: 0x0
CPU part	: 0xb76
CPU revision	: 7

Hardware	: BCM2835
Revision	: 0002
```