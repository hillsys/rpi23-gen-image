#
# First boot actions
#

# Load utility functions
. ./functions.sh

# Prepare rc.firstboot script
cat firstboot/10-begin.sh > "${ETC_DIR}/rc.firstboot"

# Ensure openssh server host keys are regenerated on first boot
cat firstboot/21-generate-ssh-keys.sh >> "${ETC_DIR}/rc.firstboot"

# Ensure that dbus machine-id exists
cat firstboot/24-generate-machineid.sh >> "${ETC_DIR}/rc.firstboot"

# Create /etc/resolv.conf symlink
cat firstboot/25-create-resolv-symlink.sh >> "${ETC_DIR}/rc.firstboot"

# Finalize rc.firstboot script
cat firstboot/99-finish.sh >> "${ETC_DIR}/rc.firstboot"
chmod +x "${ETC_DIR}/rc.firstboot"

# Install default rc.local if it does not exist
if [ ! -f "${ETC_DIR}/rc.local" ] ; then
  install_exec files/rc.local "${ETC_DIR}/rc.local"
fi

# Add rc.firstboot script to rc.local
sed -i '/exit 0/d' "${ETC_DIR}/rc.local"
echo /etc/rc.firstboot >> "${ETC_DIR}/rc.local"
echo exit 0 >> "${ETC_DIR}/rc.local"