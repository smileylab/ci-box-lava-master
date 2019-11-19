#!/bin/bash

#
# Setup lava workers and their devices
#
for worker in $(ls /root/devices/)
do
	echo "===== Handle workers ====="
	echo "Adding worker $worker"
	lava-server manage workers add $worker || exit $?
	for device in $(ls /root/devices/$worker/)
	do
		devicename=$(echo $device | sed 's,.jinja2,,')
		devicetype=$(grep -h extends /root/devices/$worker/$device| grep -o '[a-zA-Z0-9_-]*.jinja2' | sed 's,.jinja2,,')
		if [ -e /root/.lavadocker/devicetype-$devicetype ];then
			echo "Skip devicetype $devicetype"
		else
			echo "Add devicetype $devicetype"
			lava-server manage device-types add $devicetype || exit $?
			touch /root/.lavadocker/devicetype-$devicetype
		fi
		echo "Add device $devicename on $worker"
		cp /root/devices/$worker/$device /etc/lava-server/dispatcher-config/devices/ || exit $?
		lava-server manage devices add --device-type $devicetype --worker $worker $devicename || exit $?
	done
done
exit 0
