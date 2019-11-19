#!/bin/bash

#
# Setup lava users
#
if [ -e /root/lava-users ];then
	echo "===== Handle users ====="
	for ut in $(ls /root/lava-users)
	do
		# User is the filename
		USER=$ut
		USER_OPTION=""
		STAFF=0
		SUPERUSER=0
		TOKEN=""
		. /root/lava-users/$ut
		if [ -z "$PASSWORD" -o "$PASSWORD" = "$TOKEN" ];then
			echo "Generating password..."
			#Could be very long, should be avoided
			PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		fi
		if [ $STAFF -eq 1 ];then
			USER_OPTION="$USER_OPTION --staff"
		fi
		if [ $SUPERUSER -eq 1 ];then
			USER_OPTION="$USER_OPTION --superuser"
		fi
		lava-server manage users list --all > /tmp/allusers
		if [ $? -ne 0 ];then
			echo "ERROR: cannot generate user list"
			exit 1
		fi
		#filter first name/last name (enclose by "()")
		sed -i 's,[[:space:]](.*$,,' /tmp/allusers
		grep -q "[[:space:]]${USER}$" /tmp/allusers
		if [ $? -eq 0 ];then
			echo "Skip already existing $USER DEBUG(with $TOKEN / $PASSWORD / $USER_OPTION)"
		else
			echo "Adding username $USER DEBUG(with $TOKEN / $PASSWORD / $USER_OPTION)"
			lava-server manage users add --passwd $PASSWORD $USER_OPTION $USER
			if [ $? -ne 0 ];then
				echo "ERROR: Adding user $USER"
				cat /tmp/allusers
				exit 1
			fi
			if [ ! -z "$TOKEN" ];then
				echo "Adding token to user $USER"
				lava-server manage tokens add --user $USER --secret $TOKEN || exit 1
			fi
			if [ ! -z "$EMAIL" ];then
				echo "Adding email to user $USER"
				lava-server manage users update --email $EMAIL $USER || exit 1
			fi
		fi
	done
fi
exit 0
