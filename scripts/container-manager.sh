#!/bin/sh
set -x

# We need to put the rootfs somewhere where we can modify some
# parts of the content on first boot (namely file permissions).
# Other than that nothing should ever modify the content of the
# rootfs.

if [ -z $SNAP ]; then
	DATA_PATH="/usr/local/share/anbox"
	ROOTFS_PATH="$DATA_PATH/rootfs"
	ANDROID_IMG="/etc/anbox/android.img"
	SCRIPTS_DIR="/usr/local/bin"
        APP_ARMOR_DIR="/"
        ANBOX_CONFIG="/etc/anbox"
else
	DATA_PATH=$SNAP_COMMON/
	ROOTFS_PATH=$DATA_PATH/rootfs
	ANDROID_IMG=$SNAP/android.img
	SCRIPTS_DIR=$SNAP/bin
	APP_ARMOR_DIR=$SNAP
	ANBOX_CONFIG=$SNAP_COMMON
	# liblxc.so.1 is in $SNAP/lib
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SNAP/lib

fi


if [ ! -e $ANDROID_IMG ]; then
	echo "ERROR: android image does not exist"
	exit 1
fi

start() {
	# Make sure our setup path for the container rootfs
	# is present as lxc is statically configured for
	# this path.
	mkdir -p $DATA_PATH/lxc

	# We start the bridge here as long as a oneshot service unit is not
	# possible. See snapcraft.yaml for further details.
	$SCRIPTS_DIR/anbox-bridge.sh start

	# Ensure FUSE support for user namespaces is enabled
	echo Y | tee /sys/module/fuse/parameters/userns_mounts || echo "WARNING: kernel doesn't support fuse in user namespaces"

	# Only try to use AppArmor when the kernel has support for it
	# TODO: Set AppArmor location when starting to use it
	AA_EXEC="$SNAP/usr/sbin/aa-exec -p unconfined --"
	if [ ! -d /sys/kernel/security/apparmor ]; then
		echo "WARNING: AppArmor support is not available!"
		AA_EXEC=""
	fi


	if [ -d /sys/kernel/security/apparmor ] ; then
		# Load the profile for our Android container
		$SNAP/sbin/apparmor_parser -r $SNAP/apparmor/anbox-container.aa
	fi

	if [ -e "$ANBOX_CONFIG"/.enable_debug ]; then
		export ANBOX_LOG_LEVEL=debug
	fi

	exec $AA_EXEC $SCRIPTS_DIR/anbox-wrapper.sh container-manager \
		--data-path=$DATA_PATH \
		--android-image=$ANDROID_IMG \
		--daemon
}

stop() {
	$SCRIPTS_DIR/anbox-bridge.sh stop
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	*)
		echo "ERROR: Unknown command '$1'"
		exit 1
		;;
esac
