#!/bin/bash

if [ ! -d "linux-4.9.30" ] ; then
    echo -e "\n### Getting kernel source.\n"
    apt source linux-source-4.9

    echo -e "\n### Cleanup downloaded files.\n"
    rm linux*.xz
    rm linux*.dsc
fi

echo -e "\n### Copy config file.\n"
cp "kernel-4.9.30/netfilter.config" linux-4.9.30/.config
CPU_CORES=$(grep -c processor /proc/cpuinfo)

echo -e "\nPlease select your Raspberry Pi model (2 or 3) followed by [ENTER]:  "
read RPI_MODEL

if [ $RPI_MODEL = 2 ] ; then
    echo -e "\n### Compiling for Raspberry Pi 2.\n"
    cd linux-4.9.30
    make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
elif [ $RPI_MODEL = 3 ] ; then
    echo -e "\n### Compiling for Raspberry Pi 3.\n"
    cd linux-4.9.30
    make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
else
    echo "\nAn incorrect model was chosen.  Rerun script and select an apporiate model."
fi