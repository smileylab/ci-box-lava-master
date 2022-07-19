ARG version=latest
FROM lavasoftware/lava-server:${version}

ARG extra_packages=""
RUN echo "install extra packages: ${extra_packages}" && apt-get -y update && apt-get -q -y -f --install-suggests install ${extra_packages} && rm -rf /var/cache/apk/*

#
# copy official health-check yaml test jobs from github BayLibre
#
ADD https://github.com/BayLibre/lava-healthchecks/archive/master.zip /root/
# copy locally defined health-check yaml test jobs
RUN if [ -f /root/master.zip ]; then unzip -o /root/master.zip -d /root/ && \
mv /root/lava-healthchecks-master/health-checks/* /etc/lava-server/dispatcher-config/health-checks/ && \
rm -rf /root/master.zip /root/lava-healthchecks-master; fi

# if there is internal healthcheck server (i.e. healthcheck_url), replace all
# downloading url from the test jobs definition to our healthcheck server
ARG healthcheck_url=""
RUN if [ -n "${healthcheck_url}" ] ; then sed -i "s,http.*blob/master,${healthcheck_url}," /etc/lava-server/dispatcher-config/health-checks/* && sed -i 's,?.*$,,' /etc/lava-server/dispatcher-config/health-checks/* ;fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/health-checks/

#
# copy all configs to /root/configs
#
COPY configs /root/configs
# lava-server config setting
RUN if [ -f /root/configs/settings.conf ]; then mv /root/configs/settings.conf /etc/lava-server/; fi

# lava-server postgres instance and password setting
RUN if [ -f /root/configs/instance.conf ]; then mv /root/configs/instance.conf /etc/lava-server/; fi
RUN if [ -f /root/configs/.pgpass ]; then mv /root/configs/.pgpass /root/ && chmod 600 /root/.pgpass; fi

# copy additional default settings for lava or other packages
RUN if [ -n "$(ls -1 /root/configs/default)" ]; then mv /root/configs/default/* /etc/default/; fi

# copy additional health-checks jobs scripts to /etc/lava-server/dispatcher-config/health-checks/
ARG healthcheck_url=""
RUN if [ -n "$(ls -1 /root/configs/health-checks)" ]; then \
if [ -n "${healthcheck_url}" ]; then sed -i "s,http[s]*://[.A-Za-z0-9]*[:0-9]*/,${healthcheck_url}/," /root/configs/health-checks/*.yaml; fi && \
mv /root/configs/health-checks/*.yaml /etc/lava-server/dispatcher-config/health-checks/ && \
rm -rf /root/configs/health-checks; fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/health-checks/

# full qualified domain name for lavalab site, default site is set as example.com
RUN if [ -f /root/configs/lava_http_fqdn ]; then mv /root/configs/lava_http_fqdn /root/; fi
# mv previous db/device/job backups for restoring
RUN if [ -n "$(ls -1 /root/configs/backup)" ]; then mkdir -p /root/backup && mv /root/configs/backup/* /root/backup/; fi
# copy zmq_authenications
RUN if [ -n "$(ls -1 /root/configs/zmq_auth)" ]; then mv /root/configs/zmq_auth/* /etc/lava-dispatcher/certificates.d/; fi
# copy additional environment setting files into /etc/lava-server/dispatcher.d/
RUN if [ -n "$(ls -1 /root/configs/env)" ]; then mv /root/configs/env/* /etc/lava-server/dispatcher.d/; fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher.d/
# copy apache2 config
RUN if [ -n "$(ls -1 /root/configs/apache2)" ]; then mv /root/configs/apache2/* /etc/apache2/; fi
# copy other default lava-server config folders
RUN if [ -d /root/configs/users ]; then mkdir -p /root/lava-users && if [ -n "$(ls -1 /root/configs/users)" ]; then mv /root/configs/users/* /root/lava-users/; fi; fi
RUN if [ -d /root/configs/groups ]; then mkdir -p /root/lava-groups && if [ -n "$(ls -1 /root/configs/groups)" ]; then mv /root/configs/groups/* /root/lava-groups/; fi; fi
RUN if [ -d /root/configs/tokens ]; then mkdir -p /root/lava-callback-tokens && if [ -n "$(ls -1 /root/configs/tokens)" ]; then mv /root/configs/tokens/* /root/lava-callback-tokens/; fi; fi
RUN if [ -d /root/configs/devices ]; then mkdir -p /root/devices && if [ -n "$(ls -1 /root/configs/devices)" ]; then mv /root/configs/devices/* /root/devices/; fi; fi
RUN if [ -d /root/configs/device-types ]; then mkdir -p /root/device-types && if [ -n "$(ls -1 /root/configs/device-types)" ]; then mv /root/configs/device-types/* /root/device-types/; fi; fi
# apply device-types patches for existing device types
RUN if [ -n "$(ls -1 /root/configs/device-types-patch)" ]; then cd /etc/lava-server/dispatcher-config/device-types/ && \
for patch in $(ls /root/configs/device-types-patch/*patch); do sed -i 's,lava_scheduler_app/tests/device-types/,,' $patch && \
echo $patch && patch < $patch || exit $?; done; fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/device-types/
# Finally remove copied configs
RUN rm -rf /root/configs

# additional patching for python3 dist-packages
COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch | sort) ; do echo $patch && patch -p1 < $patch || exit $?;done

# start up bash scripts, have to prefix script filename with a 2 digit number for correct starting order
COPY entrypoint.d/*sh /root/entrypoint.d/
RUN chmod +x /root/entrypoint.d/*.sh
# setup lava-coordinator 99_lava-coordinator.sh is present
RUN if [ -f /root/entrypoint.d/99_lava-coordinator.sh ]; then apt-get -y update && \
apt-get -q -y --no-install-recommends install lava-coordinator && rm -rf /var/cache/apk/*; fi

# Fixes 'postgresql ERROR:  invalid locale name: "en_US.UTF-8"' when restoring a backup
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8

# TODO: send this fix to upstream
RUN if [ -f /root/entrypoint.sh ]; then \
sed -i 's,find /root/entrypoint.d/ -type f,find /root/entrypoint.d/ -type f | sort,' /root/entrypoint.sh && \
sed -i 's,echo "$0,echo "========== $0,' /root/entrypoint.sh && \
sed -i 's,ing ${f}",ing ${f} ==========",' /root/entrypoint.sh; fi

# TODO: send this fix to upstream
RUN if [ -f /usr/bin/lava-coordinator ]; then sed -i 's,pidfile =.*,pidfile = "/run/lava-coordinator/lava-coordinator.pid",' /usr/bin/lava-coordinator; fi

EXPOSE 3079 5555 5556

CMD /root/entrypoint.sh && while [ true ]; do sleep 365d; done

