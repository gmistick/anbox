#!/bin/bash

if [ "$SNAP_ARCH" == "amd64" ]; then
	ARCH="x86_64-linux-gnu"
elif [ "$SNAP_ARCH" == "armhf" ]; then
	ARCH="arm-linux-gnueabihf"
else
	ARCH="$SNAP_ARCH-linux-gnu"
fi

# With recent builds on Ubuntu 16.04 the snap does not find the path to
# libpulsecommon-8.0.so anymore so we have to teach the linker manually
# where it can be found
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SNAP/usr/lib/$ARCH/pulseaudio

# liblxc.so.1 is in $SNAP/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SNAP/lib

# We set XDG_DATA_HOME to SNAP_USER_COMMON here as this will be the location we will
# create all our application launchers in. The system application launcher will
# be configured by our installer to look into this directory for available
# launchers.
export XDG_DATA_HOME="$SNAP_USER_COMMON/app-data"

# In order to support GLVND based systems we need to work around a bug in snapd
# as it does not yet expose the EGL vendor configurations from the host to snaps.
# As long as this isn't fixed we have to carry a set of configs on our own which
# may map to the host. GLVND will handle situation properly where a vendor is
# configured but the actual EGL implementation is missing.
export __EGL_VENDOR_LIBRARY_DIRS="$SNAP/glvnd"

if [ -e "$SNAP_COMMON"/.enable_debug ]; then
	export ANBOX_LOG_LEVEL=debug
fi

exec $SNAP/usr/local/bin/anbox $@
