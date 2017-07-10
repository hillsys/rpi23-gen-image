#!/bin/sh

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

# Raspberry Pi model configuration
RPI_MODEL=${RPI_MODEL:=2}
DEBIAN_RELEASE="stretch"
KERNEL_FLAVOR="vanilla"

# Set Raspberry Pi model specific configuration
if [ "$RPI_MODEL" = 2 ] ; then
  DTB_FILE=bcm2836-rpi-2-b.dtb
  DEBIAN_RELEASE_ARCH=armhf
  KERNEL_ARCH=arm
  CROSS_COMPILE=arm-linux-gnueabihf-
  KERNEL_IMAGE_SOURCE=zImage
  KERNEL_IMAGE_TARGET=linuz.img
  QEMU_BINARY=/usr/bin/qemu-arm-static
  UBOOT_CONFIG=rpi_2_defconfig
  
elif [ "$RPI_MODEL" = 3 ] ; then
  DTB_FILE=broadcom/bcm2837-rpi-3-b.dtb
  DEBIAN_RELEASE_ARCH=arm64
  KERNEL_ARCH=arm64
  CROSS_COMPILE=aarch64-linux-gnu-
  KERNEL_IMAGE_SOURCE=Image.gz
  KERNEL_IMAGE_TARGET=linux.uImage
  QEMU_BINARY=/usr/bin/qemu-aarch64-static
  UBOOT_CONFIG=rpi_3_defconfig
  
else
  echo "Error:  Only supports Raspberry Pi models 2 and 3."
  exit 1
fi

# Introduce settings
echo -n -e "\n#\n# RPi2/3 Bootstrap Settings\n#\n"
set -x

# General settings
HOSTNAME=${HOSTNAME:=rpi${RPI_MODEL}-${DEBIAN_RELEASE}}
USER_NAME=${USER_NAME:=""}
USER_LOCALE=${USER_LOCALE:="en_US.UTF-8"}

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
ENABLE_WIRELESS=${ENABLE_WIRELESS:=false}
ENABLE_SOUND=${ENABLE_SOUND:=false}

# Kernel installation settings
KERNEL_CONFIG=${KERNEL_CONFIG:="netfilter.config"}
KERNELSRC_DIR=${KERNELSRC_DIR:=""}
UBOOTSRC_DIR=${UBOOTSRC_DIR:=""}

set +x

# Packages required in the chroot build environment.  If there is an error in your packages it will not build.
APT_INCLUDES=${APT_INCLUDES:=""}
APT_INCLUDES="${APT_INCLUDES},adduser,apt,apt-listchanges,apt-utils,,base-files,bash-completion,bc,bind9-host,binfmt-support,binutils,bison,bmap-tools"
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
APT_INCLUDES="${APT_INCLUDES},xxd,xz-utils"

# nftables includes
APT_INCLUDES="${APT_INCLUDES},autoconf,libmnl-dev,libnftnl-dev,libgmp-dev,libreadline-dev,nftables"

# Chroot scripts directory
CHROOT_SCRIPTS=${CHROOT_SCRIPTS:=""}

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
  # Check if the internal wireless interface is supported by the RPi model
  elif [ "$ENABLE_WIRELESS" = true ] && [ "$RPI_MODEL" != 3 ] ; then
    echo "Error: The selected Raspberry Pi model has no internal wireless interface!"
  # Is kernel ready?
  elif [ ! -e "${KERNELSRC_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" ] ; then
    echo "Error: Linux kernel must be precompiled."
  # Is u-boot ready?
  elif [ ! -e "${UBOOTSRC_DIR}/u-boot.bin" ] ; then
    echo "Error: U-Boot bootloader must be precompiled."
  # Is firmware ready?
  #elif [ ! -d "$RPI_FIRMWARE_DIR/boot" ] ; then
  #  echo "Error: Raspberry Pi firmware directory not specified or not found!"
  # Check if ./bootstrap.d directory exists
  elif [ ! -d "./bootstrap.d/" ] ; then
    echo "Error: './bootstrap.d' required directory not found!"
  # Check if ./files directory exists
  elif [ ! -d "./files/" ] ; then
    echo "Error: './files' required directory not found!"
  # Don't clobber an old build
  elif [ -e "$BUILDDIR" ] ; then
    echo "Error: Directory ${BUILDDIR} already exists, not proceeding."
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
  echo "error: ${BUILDDIR} not enough space left to generate the output image!"
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

# Remove apt-utils
#chroot_exec apt-get purge -qq -y --force-yes apt-utils

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