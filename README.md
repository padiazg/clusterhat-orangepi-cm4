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
$ sudo ./create.sh Orangepicm4_1.0.6
```

## Differences from upstream
* As we are using images for boards different than Raspberry Pi the `/boot/cmdline.txt` is not available so we must use `/boot/orangepiEnv.txt` for setting init scripts. 
* 32bit processors are out of the scope, we on;y support 64bit proccessors. 
* Px images are out of the scope for now. I don't think the base images we use for Opi CM4 would be used by any other Rpi Zero clone.
* Mac address for br0 is set when creating the interface to keep DHCP behavior consistent if you are assigning ip addresses based on it. Check `files/usr/share/clusterctrl/interfaces*`.  

## To fix
* ~~Networking: ipv4 address not assigned~~
* clusterctrl: error `No module 'smbus'`

For support contact: https://secure.8086.net/billing/submitticket.php?step=2&deptid=1
