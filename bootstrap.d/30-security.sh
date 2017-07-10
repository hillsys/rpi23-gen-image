# Load utility functions
. ./functions.sh

chroot_exec adduser $USER_NAME
chroot_exec adduser $USER_NAME sudo 

# Enable serial console systemd style
if [ "$ENABLE_CONSOLE" = true ] ; then
  chroot_exec systemctl enable serial-getty\@ttyAMA0.service
fi