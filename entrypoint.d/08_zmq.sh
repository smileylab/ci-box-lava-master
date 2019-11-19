#!/bin/bash

#
# Setup encriptions keys for service-dispatcher zmq communications
#
if [ -e /etc/lava-dispatcher/certificates.d/$(hostname).key ];then
	echo "===== Handle ZMQ ====="
	echo "INFO: Enabling encryption"
	sed -i 's,.*ENCRYPT=.*,ENCRYPT="--encrypt",' /etc/lava-server/lava-master || exit $?
	sed -i 's,.*MASTER_CERT=.*,MASTER_CERT="--master-cert /etc/lava-dispatcher/certificates.d/$(hostname).key_secret",' /etc/lava-server/lava-master || exit $?
	sed -i 's,.*ENCRYPT=.*,ENCRYPT="--encrypt",' /etc/lava-server/lava-logs || exit $?
	sed -i 's,.*MASTER_CERT=.*,MASTER_CERT="--master-cert /etc/lava-dispatcher/certificates.d/$(hostname).key_secret",' /etc/lava-server/lava-logs || exit $?
fi
exit 0
