#!/bin/bash

if [ -d "u-boot" ] ; then
    echo -e "\n### Clone u-boot.\n"
    git clone git://git.denx.de/u-boot.git
    cd u-boot
    
    echo -e "\n### Checkout b24cf8520a per https://github.com/michaelfranzl/rpi23-gen-image.\n"
    git checkout b24cf8540a
    
    echo -e "\n### Modify rpi.h per https://github.com/michaelfranzl/rpi23-gen-image.\n"
    sed 's/BOOTENV/BOOTENV\n\n#define CONFIG_SYS_BOOTM_LEN (64 * 1024 * 1024)/' include/configs/rpi.h
fi

CPU_CORES=$(grep -c processor /proc/cpuinfo)
read -p "Please select your Raspberry Pi model (2 or 3):  " -n 1 RPI_MODEL

if [ $RPI_MODEL = 2 ] ; then
    echo -e "\n### Compiling u-boot for Raspberry Pi 2.\n"
    make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- rpi_2_defconfig all
elif [ $RPI_MODEL = 3 ] ; then
    echo -e "\n### Compiling u-boot for Raspberry Pi 3.\n"
    make -j${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rpi_3_defconfig all
else
    echo -e "\nAn incorrect model was chosen.  Rerun script and select an apporiate model."
fi