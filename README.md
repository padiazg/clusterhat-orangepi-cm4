# Cluster HAT
Scripts and files used to build Cluster HAT images from Raspbian/Ubuntu/Debian for OrangePi CM4.

**Why?**  
The Cluster CTRL page offers images for Raspberry Pi and are not usable for the Orange Pi CM4 board, also the original scripts to build these images are in https://github.com/burtyb/clusterhat-image, but they work only with Raspbian/RaspiOS for Raspberry images

This repo is meant to create only the controller images, not the Px ones as the Pi Zero clones I'm using wont use the images we use for Opi CM4.

## Building Cluster HAT Images

Create some required folders
```shell
$ mkdir build/dest
$ mkdir build/img
$ mkdir build/mnt
```

### ClusterHAT files
To build the ClusterHAT images you need the base images provided by the board manufacturer, available at the official [**Orange Pi CM4** page](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-CM4-1.html):  

The build script should work for any of the Debian based images (Debian, Ubuntu or Raspberry Pi OS). Download any and unpack it into the `build/img` folder created previously.

**Ubuntu:** https://drive.google.com/drive/folders/14wfVqszll0bjn0hYgkSInMlwsAZoFXGf  
**Debian:** https://drive.google.com/drive/folders/1MJl-pIU2I7EHDN6rlirumVkBOz7utvyE  
**Raspberry Pi OS:** https://github.com/leeboby/raspberry-pi-os-images/releases/download/opicm4/Orangepicm4_1.0.0_raspios_bullseye_server_linux5.10.160.7z  
> I'm using the Ubuntu image as it is Jammy (based on Debian 12) as tagged in the name. Curiously the Debian image is tagged as Bookworm (12) but it is actually Bullseye (11).  
> Also, despite the Ubuntu image is Bookworm the kernel is toped to 5.10, I uderstand because of the Kernel support for the Rockchip RK3566 family.

### Build the images
The build script is located in the **build** directory.

The **files/** directory contains the files extracted into the root filesystem of a Cluster HAT image.

> The original scripts repo mentions `When building arm64 images you need to be on an arm64 machine.` but I was able to create arm64 images on a Ryzen 5 machine running Linux. YMMV.

Run the create script
```shell
$ cd build
$ sudo rm -rf dest/* ||  sudo rm -rf mnt/*
$ sudo ./create.sh Orangepicm4_1.0.6
```

## I2C
Ref: https://clusterctrl.com/setup-control#controlv2

The Opi CM4 base board has ~5 I2C busses. The ClusterHAT is attached to the bus 2.

```bash
export I2CBUS=2
export I2CADDRESS=0x20

sudo i2cdump -y $I2CBUS 0x20
No size specified (using byte-data access)
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: 00 00 00 00 ff 00 00 00 00 00 ff ff ff ff ff ff    ................
10: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
20: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
30: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
40: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
50: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
60: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
70: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
80: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
90: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
a0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
b0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
c0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
d0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
e0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
f0: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................

# Get I/O expander direction register, if out != 0xff the expander has been initialised, skip to control Px
sudo i2cget -y $I2CBUS 0x20 3
0xff

# Read the logic levels on the I/O expander pins to detect POS.
# If the low nibble of this value is an 'F' (0x?F) it means all Pi Zeros are 
# powered on and the POR jumper has been cut so all Pi Zeros need to be powered 
# on before setting the expander pins to outputs.
sudo i2cget -y $I2CBUS 0x20 1
0xdf

# Make sure P1-P4 are turn off, we want to start them on demand
sudo i2cset -y -m $((2#000001111)) $I2CBUS 0x20 1 0x00

# Turn off the ALERT LED, 0xff to turn on
sudo i2cset -y -m $((2#01000000)) $I2CBUS 0x20 1 0x00

# Set all pins on the I/O expander to outputs
sudo i2cset -y $I2CBUS 0x20 3 0x00

# Version >2.0 turn HUB on (set bit 5 to 0)
sudo i2cset -y -m $((2#00100000)) $I2CBUS 0x20 1 0x00

# Turn Pi Zero P1 on (set bit 0 to 1)
sudo i2cset -y -m $((2#00000001)) $I2CBUS 0x20 1 0xff

# Turn Pi Zero P2 on (set bit 1 to 1)
sudo i2cset -y -m $((2#00000010)) $I2CBUS 0x20 1 0xff

# Turn Pi Zero P3 on (set bit 2 to 1)
sudo i2cset -y -m $((2#00000100)) $I2CBUS 0x20 1 0xff

# Turn Pi Zero P4 on (set bit 3 to 1)
sudo i2cset -y -m $((2#00001000)) $I2CBUS 0x20 1 0xff
```

## Networking
When using the cnat image of the controller and there's a dhcp server or a dns server in your network, like a pi-hole setup to use local domain plus valid certificates for it, you might need to do a small setup in order to allow communication from the controller and the Px nodes to the internet.  
> Use the `CNAT_ETH0` config variable to let the script set _eth0_ for you. 
```bash
$ sudo bash -c 'echo "auto eth0\niface eth0 inet dhcp" > /etc/network/interfaces.d/eth0'
```
Reboot or reload the networking service

## Boot from eMMC
1. Copy the image on a SD that can boot the board
```bash
# mount the SD card to copy the image
$ mount /dev/sdXX /mnt/p2

$ cp dest/Orangepicm4_1.0.6-1-ubuntu_jammy_server_linux5.10.160-ClusterCTRL-CNAT.img /mnt/p2/home/your_user
```

2. Boot the board with the SD, then copy the image to the eMMC
```bash
# identify the eMMC device
$ ls /dev/mmcblk*boot0 | cut -c1-12**

# clear the device
$ sudo dd bs=1M if=/dev/zero of=/dev/mmcblk0 count=5000 status=progress

# copy the image
$ sudo dd bs=1M \
	if=Orangepicm4_1.0.6-1-ubuntu_jammy_server_linux5.10.160-ClusterCTRL-CNAT.img \
	of=/dev/mmcblk0 \
	status=progress

$ sync && reboot
```

## Differences from upstream
* As we are using images for boards different than Raspberry Pi the `/boot/cmdline.txt` is not available so we must use `/boot/orangepiEnv.txt` for setting init scripts. 
* 32bit processors are out of the scope, we on;y support 64bit proccessors. 
* Px images are out of the scope for now. I don't think the base images we use for Opi CM4 would be used by any other Rpi Zero clone.
* Mac address for br0 is set when creating the interface to keep DHCP behavior consistent if you are assigning ip addresses based on it. Check `files/usr/share/clusterctrl/interfaces*`.
* `CNAT_ETH0` (defaults to 0) to setup the eth0 interface to use dhcp

## To fix
* ~~Networking: ipv4 address not assigned~~
* ~~clusterctrl: error `No module 'smbus'`~~
* ~~no `ethpi*` communication, missing or not loaded usb-ndis module?~~
* get the kernel identify the hat and populate the device tree `/proc/device-tree/hat/*`.  
check:
  * https://forums.raspberrypi.com/viewtopic.php?t=108134
  * https://github.com/raspberrypi/hats/blob/master/devicetree-guide.md
* ~`clusterctrl` needs privilege elevation (sudo)~~

For support contact: https://secure.8086.net/billing/submitticket.php?step=2&deptid=1
