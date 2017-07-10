# Load utility functions
. ./functions.sh

# Install and setup APT proxy configuration
if [ -z "$APT_PROXY" ] ; then
  printf "Acquire::http:Proxy \"${APT_PROXY}\";" > files/10proxy
  install_readonly files/10proxy "${ETC_DIR}/apt/apt.conf.d/10proxy"
fi

install_readonly /etc/apt/sources.list "${ETC_DIR}/apt/sources.list"

if [ -d packages ] ; then
  for package in packages/*.deb ; do
    cp $package ${R}/tmp
    chroot_exec dpkg --unpack /tmp/$(basename $package)
  done
fi

chroot_exec apt-get -qq -y -f install
chroot_exec apt-get -qq -y check
chroot_exec apt update
chroot_exec apt -y upgrade