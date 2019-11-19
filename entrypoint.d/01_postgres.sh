#!/bin/bash

#
# Setup Lava's postgres sql server
#

echo "===== Handle postgresql database ====="

LOCAL_SQL="0"
if [ -f /etc/lava-server/instance.conf ]; then
  source /etc/lava-server/instance.conf
  if [ "$LAVA_DB_SERVER" = "localhost" -o "$LAVA_DB_SERVER" = "127.0.0.1" ]; then
    LOCAL_SQL="1"
  fi
fi

if [ "$LOCAL_SQL" = "1" ]; then
  # always reset the lavaserver user on local postgres, since its password could have been reseted in a "docker build --nocache"
  if [ ! -e /root/pg_lava_password ]; then
         < /dev/urandom tr -dc A-Za-z0-9 | head -c16 > /root/pg_lava_password
  fi
  sudo -u postgres psql -c "ALTER USER lavaserver WITH PASSWORD '$(cat /root/pg_lava_password)';" || exit $?
  sed -i "s,^LAVA_DB_PASSWORD=.*,LAVA_DB_PASSWORD='$(cat /root/pg_lava_password)'," /etc/lava-server/instance.conf || exit $?
#else
# we don't want to change remote user password
#  psql -U $LAVA_DB_USER -h $LAVA_DB_SERVER -p $LAVA_DB_PORT -c "ALTER USER $LAVA_DB_USER WITH PASSWROD '$(cat /root/pg_lava_password)';" || exit $?
fi

# Extract the postgresql database if it is gzipped
if [ -e /root/backup/db_lavaserver.gz ];then
	gunzip /root/backup/db_lavaserver.gz || exit $?
fi

# Restore the postgresql database
if [ -e /root/backup/db_lavaserver ];then
	echo "Restore database from backup"
  if [ "$LOCAL_SQL" = "1" ]; then
    sudo -u postgres psql < /root/backup/db_lavaserver || exit $?
  else
    psql -U $LAVA_DB_USER -h $LAVA_DB_SERVER -p $LAVA_DB_PORT < /root/backup/db_lavaserver || exit $?
  fi
	yes yes | lava-server manage migrate || exit $?
fi

# default site is set as example.com
if [ -e /root/lava_http_fqdn ];then
  if [ "$LOCAL_SQL" = "1" ]; then
    sudo -u postgres psql lavaserver -c "UPDATE django_site SET name = '$(cat /root/lava_http_fqdn)'" || exit $?
    sudo -u postgres psql lavaserver -c "UPDATE django_site SET domain = '$(cat /root/lava_http_fqdn)'" || exit $?
  else
    psql -U $LAVA_DB_USER -h $LAVA_DB_SERVER -p $LAVA_DB_PORT $LAVA_DB_NAME -c "UPDATE django_site SET name = '$(cat /root/lava_http_fqdn)'" || exit $?
    psql -U $LAVA_DB_USER -h $LAVA_DB_SERVER -p $LAVA_DB_PORT $LAVA_DB_NAME -c "UPDATE django_site SET domain = '$(cat /root/lava_http_fqdn)'" || exit $?
  fi
fi
exit 0
