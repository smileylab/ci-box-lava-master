#!/bin/bash

#
# Setup lava tokens for users
#
if [ -e /root/lava-callback-tokens ];then
	echo "===== Handle tokens ====="
	for ct in $(ls /root/lava-callback-tokens)
	do
		. /root/lava-callback-tokens/$ct
		if [ -z "$USER" ];then
			echo "Missing USER"
			exit 1
		fi
		if [ -z "$TOKEN" ];then
			echo "Missing TOKEN for $USER"
			exit 1
		fi
		if [ -z "$DESCRIPTION" ];then
			echo "Missing DESCRIPTION for $USER"
			exit 1
		fi
		lava-server manage tokens list --user $USER |grep -q $TOKEN
		if [ $? -eq 0 ];then
			echo "SKIP already present token for $USER"
		else
			echo "Adding $USER ($DESCRIPTION) DEBUG($TOKEN)"
			lava-server manage tokens add --user $USER --secret $TOKEN --description "$DESCRIPTION" || exit 1
		fi
	done
fi
exit 0
