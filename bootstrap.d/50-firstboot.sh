#
# First boot actions
#

# Load utility functions
. ./functions.sh

# Copy first boot script to chroot directory
cp files/rc.firstboot "${ETC_DIR}/rc.firstboot"
chmod +x "${ETC_DIR}/rc.firstboot"

# Install default rc.local if it does not exist
if [ ! -f "${ETC_DIR}/rc.local" ] ; then
  install_exec files/rc.local "${ETC_DIR}/rc.local"
fi

# Add rc.firstboot script to rc.local
sed -i '/exit 0/d' "${ETC_DIR}/rc.local"
echo /etc/rc.firstboot >> "${ETC_DIR}/rc.local"
echo exit 0 >> "${ETC_DIR}/rc.local"