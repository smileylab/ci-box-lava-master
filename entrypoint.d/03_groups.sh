#!/bin/bash

#
# Setup lava groups
#
if [ -e /root/lava-groups ];then
	echo "===== Handle groups ====="
	GROUP_CURRENT_LIST=/tmp/group.list
	lava-server manage groups list > ${GROUP_CURRENT_LIST}.raw || exit 1
	grep '^\*' ${GROUP_CURRENT_LIST}.raw > ${GROUP_CURRENT_LIST}
	for group in $(ls /root/lava-groups/*group)
	do
		GROUPNAME=""
		SUBMIT=0
		OPTION_SUBMIT=""
		. $group
		grep -q $GROUPNAME $GROUP_CURRENT_LIST
		if [ $? -eq 0 ];then
			echo "DEBUG: SKIP creation of $GROUPNAME which already exists"
		else
			if [ $SUBMIT -eq 1 ];then
				echo "DEBUG: $GROUPNAME can submit jobs"
				OPTION_SUBMIT="--submitting"
			fi
			echo "DEBUG: Add group $GROUPNAME"
			lava-server manage groups add $OPTION_SUBMIT $GROUPNAME || exit 1
		fi
		if [ -e ${group}.list ];then
			echo "DEBUG: Found ${group}.list"
			while read username
			do
				echo "DEBUG: Add user $username to group $GROUPNAME"
				lava-server manage groups update --username $username $GROUPNAME || exit 1
			done < ${group}.list
		fi
	done
fi
exit 0
