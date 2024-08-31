# Cluster HAT
Scripts and files used to build Cluster HAT images from Raspbian/Ubuntu/Debian for OrangePi CM4.

**Why?**  
The Cluster CTRL page offers images for Raspberry Pi and are not usable for the Orange Pi CM4 board, also the original scripts to build these images are in https://github.com/burtyb/clusterhat-image, but they work only with Raspbian/RaspiOS for Raspberry images


## Building Cluster HAT Images

Create some required folders
```shell
$ mkdir build/dest
$ mkdir build/img
$ mkdir build/mnt
```

### ClusterHAT files
The images can be downloaded from the official page: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-CM4-1.html

The build script should work for any of the Debian based images (Debian, Ubuntu or Raspberry Pi OS). Download any and unpack it into the build/img folder created previously.

**Ubuntu:** https://drive.google.com/drive/folders/14wfVqszll0bjn0hYgkSInMlwsAZoFXGf  
**Debian:** https://drive.google.com/drive/folders/1MJl-pIU2I7EHDN6rlirumVkBOz7utvyE  
**Raspberry Pi OS:** https://github.com/leeboby/raspberry-pi-os-images/releases/download/opicm4/Orangepicm4_1.0.0_raspios_bullseye_server_linux5.10.160.7z  


### Build the images
The build script is located in the build directory.

The `files/` directory contains the files extracted into the root filesystem of a Cluster HAT image.

Create a `config-local.sh` file to set some variables
```shell

```

> The original scripts repo mentions `When building arm64 images you need to be on an arm64 machine.` but I was able to create arm64 images on a Ryzen 5 machine running Linux. YMMV.

Run the create script
```shell
$ cd build
$ sudo create.sh
```

For support contact: https://secure.8086.net/billing/submitticket.php?step=2&deptid=1
