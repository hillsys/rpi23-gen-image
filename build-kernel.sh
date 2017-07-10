#!/bin/bash

if [ ${COMPILE_KERNEL} = true ]
    if [ -d "linux-source-4.9" ] ; then
        apt source linux-source-4.9
    fi

    cp "kernel-4.9.30/${KERNEL_CONFIG}" linux-source-4.9.30/.config
    CPU_CORES=$(grep -c processor /proc/cpuinfo)

    if [ $RPI_MODEL = 2 ] ; then
        linux-source-4.9.30/make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
    elif [ $RPI_MODEL = 3 ] ; then
        linux-source-4.9.30/make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
    else
        exit 1
    fi
fi

if [ ! -e "${KERNELSRC_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" ] ; then
    echo "Error: Linux kernel must be precompiled."
    exit 1
fi