# Load utility functions
. ./functions.sh

chroot_exec cp /etc/timezone "${ETC_DIR}/timezone"
chroot_exec export LANG="${USER_LOCALE}"
chroot_exec locale-gen "${USER_LOCALE}"
chroot_exec dpkg-reconfigure locales