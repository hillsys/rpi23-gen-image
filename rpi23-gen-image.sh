#!/bin/sh
#    Script to create Debian 9 image for Raspberry Pi 2/3
#    Copyright (C) 2017  Paul Hill  paul@hillsys.org
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    Based on https://github.com/michaelfranzl/rpi23-gen-image by Michael Franzl
#    and https://github.com/drtyhlpr/rpi23-gen-image by drtyhlpr


echo -e "\n\n### Getting Firmware \n"
set -x
# URLs
BOOT_FIRMWARE_URL=https://github.com/raspberrypi/firmware/raw/master/boot
WIRELESS_FIRMWARE_URL=https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm80211/brcm

# Get firmware
if [ ! -d "firmware" ] ; then
    mkdir -p firmware/boot
    mkdir -p firmware/wireless

    # Wireless 
    wget -q -O "firmware/wireless/brcmfmac43430-sdio.bin" "${WIRELESS_FIRMWARE_URL}/brcmfmac43430-sdio.bin"
    wget -q -O "firmware/wireless/brcmfmac43430-sdio.txt" "${WIRELESS_FIRMWARE_URL}/brcmfmac43430-sdio.txt"
    
    # Boot
    wget -q -O "firmware/boot/bootcode.bin" "${BOOT_FIRMWARE_URL}/bootcode.bin"
    wget -q -O "firmware/boot/fixup_cd.dat" "${BOOT_FIRMWARE_URL}/fixup_cd.dat"
    wget -q -O "firmware/boot/fixup.dat" "${BOOT_FIRMWARE_URL}/fixup.dat"
    wget -q -O "firmware/boot/fixup_x.dat" "${BOOT_FIRMWARE_URL}/fixup_x.dat"
    wget -q -O "firmware/boot/start_cd.elf" "${BOOT_FIRMWARE_URL}/start_cd.elf"
    wget -q -O "firmware/boot/start.elf" "${BOOT_FIRMWARE_URL}/start.elf"
    wget -q -O "firmware/boot/start_x.elf" "${BOOT_FIRMWARE_URL}/start_x.elf"
fi

echo -e "\n\n### Static Settings \n"

# Build directories
BASEDIR="$(pwd)/images"
BUILDDIR="${BASEDIR}/build"

# Chroot directories
R="${BUILDDIR}/chroot"
ETC_DIR="${R}/etc"
LIB_DIR="${R}/lib"
BOOT_DIR="${R}/boot/firmware"
KERNEL_DIR="${R}/usr/src/linux"
WLAN_FIRMWARE_DIR="${R}/lib/firmware/brcm"

# Debian & U-Boot Settings
DEBIAN_RELEASE="stretch"
KERNEL_FLAVOR="vanilla"
KERNELSRC_DIR="linux-4.9.30"
UBOOTSRC_DIR="u-boot"

echo -e "\n\n### User Defined Settings.  See en-us.sh for example. \n"

# General settings
HOSTNAME=${HOSTNAME:=rpi${RPI_MODEL}-${DEBIAN_RELEASE}}
USER_NAME=${USER_NAME:=""}
USER_LOCALE=${USER_LOCALE:="en_US.UTF-8"}
RPI_MODEL=${RPI_MODEL:=2}

# Network settings
ENABLE_CONSOLE=${ENABLE_CONSOLE:=true}
ENABLE_DHCP=${ENABLE_DHCP:=true}
ENABLE_IPV6=${ENABLE_IPV6:=true}

# Network settings (static)
NET_ADDRESS=${NET_ADDRESS:=""}
NET_MASK=${NET_MASK:=""}
NET_GATEWAY=${NET_GATEWAY:=""}
NET_DNS_1=${NET_DNS_1:=""}
NET_DNS_2=${NET_DNS_2:=""}

# NTP Settings
NET_NTP_1=${NET_NTP_1:=""}
NET_NTP_2=${NET_NTP_2:=""}

# APT settings
APT_PROXY=${APT_PROXY:=""} 
APT_SERVER=${APT_SERVER:=""}
ENABLE_NONFREE=${ENABLE_NONFREE:=false}

# Feature settings
ENABLE_SOUND=${ENABLE_SOUND:=false}

set +x

if [ ${RPI_MODEL} = 2 ] ; then
          DTB_FILE=bcm2836-rpi-2-b.dtb
          DEBIAN_RELEASE_ARCH=armhf
          KERNEL_ARCH=arm
          CROSS_COMPILE=arm-linux-gnueabihf-
          KERNEL_IMAGE_SOURCE=zImage
          KERNEL_IMAGE_TARGET=linuz.img
          QEMU_BINARY=/usr/bin/qemu-arm-static
          UBOOT_CONFIG=rpi_2_defconfig
elif [ ${RPI_MODEL} = 3 ] ; then
          DTB_FILE=broadcom/bcm2837-rpi-3-b.dtb
          DEBIAN_RELEASE_ARCH=arm64
          KERNEL_ARCH=arm64
          CROSS_COMPILE=aarch64-linux-gnu-
          KERNEL_IMAGE_SOURCE=Image.gz
          KERNEL_IMAGE_TARGET=linux.uImage
          QEMU_BINARY=/usr/bin/qemu-aarch64-static
          UBOOT_CONFIG=rpi_3_defconfig
else
  echo "Error:  Incorrect Raspberry Pi model chosen.  Please correct your script and select 2 or 3 for RPI_MODEL."
  exit 1
fi

# Packages required in the chroot build environment.  If there is an error in your packages it will not build.
APT_INCLUDES=${APT_INCLUDES:=""}
APT_INCLUDES="${APT_INCLUDES},adduser,apt,apt-listchanges,apt-utils,autoconf,base-files,bash-completion,bc,bind9-host,binfmt-support,binutils,bison,bmap-tools"
APT_INCLUDES="${APT_INCLUDES},bsdmainutils,build-essential,bzip2,ca-certificates,console-setup,console-setup-linux,cpio,cpp,cpp-6,cron,dbus,debconf-i18n"
APT_INCLUDES="${APT_INCLUDES},debian-archive-keyring,debian-faq,device-tree-compiler,dh-python,dictionaries-common,discover,discover-data,distro-info-data"
APT_INCLUDES="${APT_INCLUDES},dmidecode,dmsetup,doc-debian,dosfstools,dpkg-cross,dpkg-dev,efibootmgr,eject,emacsen-common,exim4,exim4-base,exim4-config"
APT_INCLUDES="${APT_INCLUDES},exim4-daemon-light,fakeroot,file,flex,g++,g++-6,gcc,gcc-6,gcc-6-cross-base,geoip-database,gettext-base,git,git-man,gnupg"
APT_INCLUDES="${APT_INCLUDES},gnupg-agent,gpgv,groff-base,grub-common,grub2-common,guile-2.0-libs,hdparm,i2c-tools,ifupdown,init,initramfs-tools,initramfs-tools-core"
APT_INCLUDES="${APT_INCLUDES},installation-report,iproute2,iputils-ping,isc-dhcp-client,isc-dhcp-common,iso-codes,ispell,kbd,keyboard-configuration"
APT_INCLUDES="${APT_INCLUDES},klibc-utils,kmod,krb5-locales,laptop-detect,less,linux-base,linux-libc-dev,locales,logrotate,lsb-release,lsof,lzop"
APT_INCLUDES="${APT_INCLUDES},mailutils,mailutils-common,make,man-db,manpages,manpages-dev,mime-support,nano,ncurses-term,netbase,netcat-traditional,nftables"
APT_INCLUDES="${APT_INCLUDES},openssh-client,openssh-server,openssh-sftp-server,openssl,os-prober,patch,pciutils,perl,perl-modules-5.24,perl-openssl-defaults"
APT_INCLUDES="${APT_INCLUDES},pinentry-curses,powermgmt-base,procps,psmisc,python,python-apt-common,python-gpgme,python-minimal,python2.7,python2.7-minimal"
APT_INCLUDES="${APT_INCLUDES},python3,python3-apt,python3-chardet,python3-debian,python3-debianbts,python3-httplib2,python3-minimal,python3-pkg-resources"
APT_INCLUDES="${APT_INCLUDES},python3-pycurl,python3-pysimplesoap,python3-reportbug,python3-requests,python3-six,python3-urllib3,python3.5,python3.5-minimal"
APT_INCLUDES="${APT_INCLUDES},readline-common,rename,reportbug,rng-tools,rsync,rsyslog,sgml-base,sudo,systemd,systemd-sysv,task-ssh-server,tasksel,tasksel-data"
APT_INCLUDES="${APT_INCLUDES},tcpd,telnet,traceroute,ucf,udev,util-linux-locales,vim-common,vim-tiny,wget,whiptail,whois,xauth,xkb-data,xml-core"
APT_INCLUDES="${APT_INCLUDES},xxd,xz-utils,libgmp-dev,libreadline-dev"

# Packages required for bootstrapping  (host PC)
REQUIRED_PACKAGES="debootstrap debian-archive-keyring qemu-user-static binfmt-support dosfstools rsync bmap-tools whois git"
MISSING_PACKAGES=""

validation_check(){
  local result_variable=$1
  local validation_result=false

  # Are we running as root?
  if [ "$(id -u)" -ne "0" ] ; then
    echo "Error: This script must be executed with root privileges!"
  # Is functions script available
  elif [ ! -r "./functions.sh" ] ; then
    echo "Error: './functions.sh' required script not found!"
  elif [ ! -d "./pmg" ] ; then
    echo "Error: './pmg' required directory not found!"
  # Is u-boot ready?
  elif [ ! -e "${UBOOTSRC_DIR}/u-boot.bin" ] ; then
    echo "Error: U-Boot bootloader must be precompiled."
  elif [ ! -d "./bootstrap.d/" ] ; then
    echo "Error: './bootstrap.d' required directory not found!"
  # Check if ./files directory exists
  elif [ ! -d "./files/" ] ; then
    echo "Error: './files' required directory not found!"
  # Don't clobber an old build
  elif [ -e "$BUILDDIR" ] ; then
    while read -p "Build directory found, do you wish to overwrite? [y/n]  " -n 1 OVERWRITE_BUILD ; do
      case $RPI_MODEL in
          y)
              echo -e "\n### Removing build directory.\n"
              rm -r images
              break;;
          n) exit 0;;
          *) echo "Please select y/n.";;
      esac
    done
  elif [ ! -e "${KERNELSRC_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" ] ; then
    echo "Error: ${KERNELSRC_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE} not found.  Linux kernel must be precompiled."
  else
    validation_result=true
  fi

  eval $result_variable="'$validation_result'"
}

validation_check validation_check_result

if [ "$validation_check_result" = false ] ; then
  exit 1
fi

# Setup chroot directory
mkdir -p "${R}"

# Check if build directory has enough of free disk space >512MB
if [ "$(df --output=avail ${BUILDDIR} | sed "1d")" -le "524288" ] ; then
  echo "Error: ${BUILDDIR} not enough space left to generate the output image!"
  exit 1
fi

# Load utility functions
. ./functions.sh

# Check if all required packages are installed on the build system
for package in $REQUIRED_PACKAGES ; do
  if [ "`dpkg-query -W -f='${Status}' $package`" != "install ok installed" ] ; then
    MISSING_PACKAGES="${MISSING_PACKAGES} $package"
  fi
done

# Ask if missing packages should be installed right now
if [ -n "$MISSING_PACKAGES" ] ; then
  echo "the following packages needed by this script are not installed:"
  echo "$MISSING_PACKAGES"

  echo -n "\ndo you want to install the missing packages right now? [y/n] "
  read confirm
  if [ "$confirm" != "y" ] ; then
    exit 1
  else
    apt-get -qq -y install ${REQUIRED_PACKAGES}
  fi
fi

set -x

# Call "cleanup" function on various signals and errors
trap cleanup 0 1 2 3 6

# Add alsa-utils package
if [ "$ENABLE_SOUND" = true ] ; then
  APT_INCLUDES="${APT_INCLUDES},alsa-utils"
fi

# Execute bootstrap scripts
for SCRIPT in bootstrap.d/*.sh; do
  head -n 3 "$SCRIPT"
  . "$SCRIPT"
done

# Generate required machine-id
MACHINE_ID=$(dbus-uuidgen)
echo -n "${MACHINE_ID}" > "${R}/var/lib/dbus/machine-id"
echo -n "${MACHINE_ID}" > "${ETC_DIR}/machine-id"

# APT Cleanup
chroot_exec apt-get -y clean
chroot_exec apt-get -y autoclean
chroot_exec apt-get -y autoremove

# Unmount mounted filesystems
umount -l "${R}/proc"
umount -l "${R}/sys"

# Clean up directories
rm -rf "${R}/run/*"
rm -rf "${R}/tmp/*"

# Clean up files
rm -f "${ETC_DIR}/ssh/ssh_host_*"
rm -f "${ETC_DIR}/apt/sources.list.save"
rm -f "${ETC_DIR}/resolvconf/resolv.conf.d/original"
rm -f "${ETC_DIR}/*-"
rm -f "${ETC_DIR}/apt/apt.conf.d/10proxy"
rm -f "${ETC_DIR}/resolv.conf"
rm -f "${R}/root/.bash_history"
rm -f "${R}/var/lib/urandom/random-seed"
rm -f "${R}/initrd.img"
rm -f "${R}/vmlinuz"
rm -f "${R}${QEMU_BINARY}"

echo ""
echo "DONE!"
echo ""