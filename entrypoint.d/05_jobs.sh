#!/bin/bash

# Restore backed-up jobs
if [ -e /root/backup/joboutput.tar.gz ]; then
	echo "===== Handle jobs ====="
	echo "Restore jobs output from backup"
	rm -r /var/lib/lava-server/default/media/job-output/*
	tar xzf /root/backup/joboutput.tar.gz || exit $?
	chown -R lavaserver:lavaserver /var/lib/lava-server/default/media/job-output/
fi
exit 0
