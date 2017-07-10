# Load utility functions
. ./functions.sh

# Install and setup hostname
printf "${HOSTNAME}" > files/hostname
install_readonly files/hostname "${ETC_DIR}/hostname"

# Install and setup hosts
HOSTS_FILE="127.0.0.1\tlocalhost\n127.0.0.1\t${HOSTNAME}\n"

if [ "$ENABLE_IPV6" = true ] ; then
  HOSTS_FILE="${HOSTS_FILE}\n::1\tlocalhost ip6-localhost ip6-loopback\nff02::1\tip6-allnodes\nff02::2\tip6-allrouters"
fi

printf "${HOSTS_FILE}" > files/hosts
install_readonly files/hosts "${ETC_DIR}/hosts"

# NTP pool.  See http://www.pool.ntp.org
printf "[Time]\nNTP=${NET_NTP_1} ${NET_NTP_2}\nFallbackNTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org" > files/timesyncd.conf
install_readonly files/timesyncd.conf "${ETC_DIR}/systemd/timesycd.conf"
chroot_exec systemctl enable systemd-timesyncd.service

# Install and setup interfaces
INTERFACES_FILE="source /etc/network/interfaces.d/*\n\n# The loopback network interface\nauto lo\niface lo inet loopback\n"
INTERFACES_FILE="${INTERFACES_FILE}\n# The primary network interface\nauto eth0\nallow-hotplug eth0\niface eth0 inet"
MAC_ADDRESS=`pmg/pmg -u -s : --lower | cut -c 24-42`

# Setup hostname entry with static IP
if [ "$NET_ADDRESS" != "" ] ; then
  INTERFACES_FILE="${INTERFACES_FILE} static\n\thwaddress ${MAC_ADDRESS}\n\taddress ${NET_ADDRESS}\n\tnetmask ${NET_MASK}"
  INTERFACES_FILE="${INTERFACES_FILE}\n\tgateway ${NET_GATEWAY}\n\tdns-nameservers ${NET_DNS_1} ${NET_DNS_2}"
else
  INTERFACES_FILE="${INTERFACES_FILE} dhcp\n\thwaddress ${MAC_ADDRESS}"
fi

printf "${INTERFACES_FILE}" > files/interfaces
install_readonly files/interfaces "${ETC_DIR}/network/interfaces"

# Enable systemd-networkd service
chroot_exec systemctl enable systemd-networkd

# Remove iptables and enable nftables
chroot_exec apt remove iptables
chroot_exec systemctl enable nftables

# Install host.conf resolver configuration
printf "# spoof warn\nmulti on" > files/host.conf
install_readonly files/host.conf "${ETC_DIR}/host.conf"

# Install wireless binaries required to use the RPi3 wireless interface
if [ "$ENABLE_WIRELESS" = true ] ; then
  if [ ! -d ${WLAN_FIRMWARE_DIR} ] ; then
    mkdir -p ${WLAN_FIRMWARE_DIR}
  fi

  cp firmware/wireless/brcmfmac43430-sdio.bin "${WLAN_FIRMWARE_DIR}/brcmfmac43430-sdio.bin"
  cp firmware/wireless/brcmfmac43430-sdio.txt "${WLAN_FIRMWARE_DIR}/brcmfmac43430-sdio.txt"
fi
