#!/bin/bash

if [ ! -d "linux-4.9.30" ] ; then
    echo -e "\n### Getting kernel source.\n"
    apt source linux-source-4.9

    echo -e "\n### Cleanup downloaded files.\n"
    rm linux*.xz
    rm linux*.dsc
fi

cd linux-4.9.30
echo -e "\n### Clean image.\n"
make mrproper

echo -e "\n### Copy config file.\n"
cd ..
cp files/kernel.config linux-4.9.30/.config
CPU_CORES=$(grep -c processor /proc/cpuinfo)
cd linux-4.9.30

while read -p "Please select your Raspberry Pi model (2, 3 or q to quit):  " -n 1 RPI_MODEL ; do
    case $RPI_MODEL in
        2)
            echo -e "\n### Compiling for Raspberry Pi 2.\n"
            make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
            break;;
        3)
            echo -e "\n### Compiling for Raspberry Pi 3.\n"
            make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
            break;;
        q) exit 0;;
        *) echo "Please select 2, 3 or q to quit.";;
    esac
done