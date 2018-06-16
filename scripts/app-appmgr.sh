#!/bin/sh

PACKAGE=org.anbox.appmgr
COMPONENT=org.anbox.appmgr.AppViewActivity

exec $SNAP/usr/local/bin/anbox-wrapper.sh launch \
	--package="$PACKAGE" \
	--component="$COMPONENT"
