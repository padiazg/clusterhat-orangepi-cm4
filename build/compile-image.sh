#!/bin/bash

source ./config.sh

# Parameters
while getopts i:p: option
do
 case "${option}"
 in
 i) IMG=${OPTARG};;
 p) PNUMBER=${OPTARG};;
 esac
done

# Check directories exist
if [ ! -d "$MNT" ] ;then
 echo "\$MNT directory does not exist."
 exit
fi

cp -v $IMG $DEST/bananapim2zero-p$PNUMBER.img
IMG=$DEST/bananapim2zero-p$PNUMBER.img

# Prepare image
if [ ! -d ~/mnt ];then
  mkdir -p ~/mnt
fi
MNT=~/mnt
LOOP=`losetup -fP --show $IMG`
sleep 5
mount -o noatime,nodiratime ${LOOP}p1 $MNT

# Setup qemmu
cp /usr/bin/qemu-arm-static $MNT/usr/bin/qemu-arm-static
sed -i "s/\(.*\)/#\1/" $MNT/etc/ld.so.conf
sed -i "s/\(.*\)/#\1/" $MNT/etc/ld.so.cache

# Apt
chroot $MNT apt clean
chroot $MNT apt -y purge network-manager iw
chroot $MNT apt -y autoremove
#	chroot $MNT apt -y install nfs-common busybox initramfs-tools-core
chroot $MNT apt clean

#Transfer files
CLUSTER=~/clusterhat-image
cp $CLUSTER/files/sbin/composite-clusterctrl $MNT/sbin/composite-clusterctrl
cp $CLUSTER/files/etc/udev/rules.d/90-clusterctrl.rules $MNT/etc/udev/rules.d/90-clusterctrl.rules
cp $CLUSTER/files/lib/systemd/system/clusterctrl-composite.service $MNT/etc/systemd/system/clusterctrl-composite.service
cp $CLUSTER/files/usr/share/clusterctrl/issue.p $MNT/etc/issue
cp $CLUSTER/files/usr/share/clusterctrl/default-clusterctrl $MNT/etc/default/clusterctrl

# Configure specific p1-4 configuration
echo "TYPE=node" >> $MNT/etc/default/clusterctrl
echo "ID=$PNUMBER" >> $MNT/etc/default/clusterctrl
echo "p$PNUMBER" > $MNT/etc/hostname
sed -i "s/bananapim2zero/p$PNUMBER/g" $MNT/etc/hosts
echo $'\n' >> $MNT/etc/hosts
echo "127.0.1.1   p$PNUMBER" >> $MNT/etc/hosts

# Network configuration
#	sed -i "s/managed=true/managed=false/g" $MNT/etc/NetworkManager/NetworkManager.conf
cat << EOF >> ~/mnt/etc/network/interfaces

auto usb0
allow-hotplug usb0
iface usb0 inet dhcp
metric 101
up ip addr add 172.19.181.XXX/24 dev usb0 label usb0:1
up ip route add 172.19.181.0/24 via 172.19.181.254 dev usb0:1 metric 121
down ip addr del 172.19.181.XXX/24 dev usb0 label usb0:1
down ip route del 172.19.181.0/24 via 172.19.181.254 dev usb0:1 metric 121

iface wlan0 inet manual
iface eth0 inet manual
EOF
sed -i "s/XXX/$PNUMBER/g" $MNT/etc/network/interfaces

# Enable SSH
touch $MNT/boot/ssh
chroot $MNT systemctl enable ssh

# Enable services - Serial is still incosistent in BananaPi
#	touch $MNT/etc/systemd/system/getty.target.wants/getty@ttyGS0.service
#	ln -fs $MNT/lib/systemd/system/getty@.service $MNT/etc/systemd/system/getty.target.wants/getty@ttyGS0.service
chroot $MNT systemctl enable clusterctrl-composite.service

# Setup pi user
chroot $MNT adduser pi << EOF > /dev/null
clusterctrl
clusterctrl






EOF
chroot $MNT usermod -aG tty,disk,dialout,sudo,audio,video,plugdev,games,users,systemd-journal,input,netdev,ssh pi

# Module setup
echo $'libcomposite\nsunxi\ng_ether\nusb_f_acm\nu_ether\nusb_f_rndis' > $MNT/etc/modules
mkdir -p $MNT/etc/modprobe.d
cat << EOF >> $MNT/etc/modprobe.d/blacklist.conf
blacklist usb_f_eem
blacklist brcmfmac
EOF

# Remove qemu
rm $MNT/usr/bin/qemu-arm-static
sed -i "s/^#//" $MNT/etc/ld.so.conf
sed -i "s/^#//" $MNT/etc/ld.so.cache

# Shrink image
P_START=$( fdisk -lu $IMG | grep Linux | awk '{print $2}' ) # Start of 2nd partition in 512 byte sectors
P_SIZE=$(( $( fdisk -lu $IMG | grep Linux | awk '{print $3}' ) * 1024 )) # Partition size in bytes

umount $MNT
losetup -d $LOOP
LOOP=`losetup -fP --show $IMG -o $(($P_START * 512)) --sizelimit $P_SIZE`
fsck -f $LOOP
resize2fs -M $LOOP # Make the filesystem as small as possible
fsck -f $LOOP
P_NEWSIZE=$( dumpe2fs $LOOP 2>/dev/null | grep '^Block count:' | awk '{print $3}' ) # In 4k blocks
P_NEWEND=$(( $P_START + ($P_NEWSIZE * 8) + 1 )) # in 512 byte sectors
losetup -d $LOOP
echo -e "p\nd\nn\np\n1\n$P_START\n$P_NEWEND\np\nw\n" | fdisk $IMG
I_SIZE=$((($P_NEWEND + 1) * 512)) # New image size in bytes
truncate -s $I_SIZE $IMG

exit 0