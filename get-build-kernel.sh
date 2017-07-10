#!/bin/bash

if [ ! -d "linux-4.9.30" ] ; then
    echo -e "\n\n### Getting kernel source.\n"
    apt source linux-source-4.9
fi

cp "kernel-4.9.30/${KERNEL_CONFIG}" linux-4.9.30/.config
CPU_CORES=$(grep -c processor /proc/cpuinfo)

if [ $RPI_MODEL = 2 ] ; then
    linux-source-4.9.30/make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
elif [ $RPI_MODEL = 3 ] ; then
    linux-source-4.9.30/make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
else
    exit 1
fi