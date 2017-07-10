# Load utility functions
. ./functions.sh

# Base debootstrap (unpack only)
http_proxy=${APT_PROXY} debootstrap --arch="${DEBIAN_RELEASE_ARCH}" --foreign --components="main" --include="${APT_INCLUDES}" "${DEBIAN_RELEASE}" "${R}" "http://${APT_SERVER}/debian"

# Copy qemu emulator binary to chroot
install_exec "${QEMU_BINARY}" "${R}${QEMU_BINARY}"

# Copy debian-archive-keyring.pgp
mkdir -p "${R}/usr/share/keyrings"
install_readonly /usr/share/keyrings/debian-archive-keyring.gpg "${R}/usr/share/keyrings/debian-archive-keyring.gpg"

# Complete the bootstrapping process
chroot_exec /debootstrap/debootstrap --second-stage

# Mount required filesystems
mount -t proc none "${R}/proc"
mount -t sysfs none "${R}/sys"

# Mount pseudo terminal slave if supported by Debian release
if [ -d "${R}/dev/pts" ] ; then
  mount --bind /dev/pts "${R}/dev/pts"
fi