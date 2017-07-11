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
cd linux-4.9.30

CPU_CORES=$(grep -c processor /proc/cpuinfo)
while read -p "Please select your Raspberry Pi model (2, 3 or q to quit):  " -n 1 RPI_MODEL && [[ $RPI_MODEL != q ]]
    case $RPI_MODEL
        2)
            echo -e "\n### Compiling for Raspberry Pi 2.\n"
            make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-;;
        3)
            echo -e "\n### Compiling for Raspberry Pi 3.\n"
            make -j ${CPU_CORES} ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-;;
        *) echo "Please select 2, 3 or q to quit.";;
    esac
done


if [ $RPI_MODEL = 2 ] ; then

elif [ $RPI_MODEL = 3 ] ; then

else
    echo -e "\nAn incorrect model was chosen.  Rerun script and select an apporiate model."
fi