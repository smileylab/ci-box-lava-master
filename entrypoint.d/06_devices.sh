#!/bin/bash

#
# Setup lava device types into already existing devices/folder
#
# This directory is used for storing device-types already added
mkdir -p /root/.lavadocker/

if [ -e /root/backup/devices.tar.gz ];then
	echo "===== Handle devices ====="
	echo "INFO: Restoring devices files"
	tar xzf /root/backup/devices.tar.gz
	chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/devices
fi

if [ -e /root/device-types ];then
	echo "===== Handle device types ====="
	for i in $(ls /root/device-types/*jinja2)
	do
		if [ -e /etc/lava-server/dispatcher-config/device-types/$(basename $i) ];then
			echo "WARNING: overwriting device-type $i"
			diff -u "/etc/lava-server/dispatcher-config/device-types/$(basename $i)" $i
		fi
		cp $i /etc/lava-server/dispatcher-config/device-types/
		chown lavaserver:lavaserver /etc/lava-server/dispatcher-config/device-types/$(basename $i)
		devicetype=$(basename $i |sed 's,.jinja2,,')
		lava-server manage device-types list | grep -q "[[:space:]]$devicetype[[:space:]]"
		if [ $? -eq 0 ];then
			echo "Skip already known $devicetype"
		else
			echo "Adding custom $devicetype"
			lava-server manage device-types add $devicetype || exit $?
			touch /root/.lavadocker/devicetype-$devicetype
		fi
	done
fi

exit 0
