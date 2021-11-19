ARG version=latest
FROM lavasoftware/lava-server:${version}

ARG extra_packages=""
RUN echo "install extra packages: sudo git ${extra_packages}" && apt-get -y update && apt-get -q -y -f --no-install-recommends install sudo git ${extra_packages} && rm -rf /var/cache/apk/*

# ******************************************************************************
# merged from https://github.com/kernelci/lava-docker.git ./lava-master/Dockerfile
# ******************************************************************************
# mv previous db/device/job backups for restoring
COPY configs/backup /root/

# copy additional default settings for lava or other packages
COPY configs/default/* /etc/default/

# copy locally defined health-check yaml test jobs
ARG healthcheck_url=""
COPY configs/health-checks/*.yaml /etc/lava-server/dispatcher-config/health-checks/
# if there is internal healthcheck server (i.e. healthcheck_url), replace all
# downloading url from the test jobs definition to our healthcheck server
RUN if [ -n "$(ls -1 /etc/lava-server/dispatcher-config/health-checks)" ]; then \
if [ -n "${healthcheck_url}" ]; then sed -i "s,http[s]*://[.A-Za-z0-9]*[:0-9]*/,${healthcheck_url}/," /etc/lava-server/dispatcher-config/health-checks/*.yaml; fi; fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/health-checks/
# copy official health-check yaml test jobs from github BayLibre
ADD https://github.com/BayLibre/lava-healthchecks/archive/master.zip /root/
RUN if [ -f /root/master.zip ]; then unzip -o /root/master.zip -d /root/ && \
mv /root/lava-healthchecks-master/health-checks/* /etc/lava-server/dispatcher-config/health-checks/ && \
rm -rf /root/master.zip /root/lava-healthchecks-master; fi

# lava-server postgres instance and postgres password setting
#COPY configs/00-database.yaml /etc/lava-server/settings.d/
#COPY configs/.pgpass /root/
#RUN chmod 600 /root/.pgpass

COPY configs/devices/ /root/devices/
COPY configs/device-types/ /root/device-types/
COPY configs/users/ /root/lava-users/
COPY configs/groups/ /root/lava-groups/
COPY configs/tokens/ /root/lava-callback-tokens/
COPY entrypoint.d/* /root/entrypoint.d/
RUN chmod +x /root/entrypoint.d/*.sh

# lava-server config setting
COPY configs/settings.conf /etc/lava-server/

# additional patching for python3 dist-packages
COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch | sort) ; do echo $patch && patch -p1 < $patch || exit $?;done

# apply device-types patches for existing device types
COPY configs/device-types-patch/ /root/device-types-patch/
RUN sh root/device-types-patch/patch-device-type.sh

# full qualified domain name for lavalab site, default site is set as example.com
COPY configs/lava_http_fqdn /root/

# copy env dispatchers settings to lava-server
COPY configs/env/ /etc/lava-server/dispatcher.d/
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher.d/

# copy apache2 setting
COPY configs/apache2/ /etc/apache2/

# Fixes 'postgresql ERROR:  invalid locale name: "en_US.UTF-8"' when restoring a backup
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8

COPY configs/pg_lava_password /root/

# TODO: send this fix to upstream
RUN sed -i 's,find /root/entrypoint.d/ -type f,find /root/entrypoint.d/ -type f | sort,' /root/entrypoint.sh && \
sed -i 's,echo "$0,echo "========== $0,' /root/entrypoint.sh && \
sed -i 's,ing ${f}",ing ${f} ==========",' /root/entrypoint.sh

# TODO: send this fix to upstream
RUN sed -i 's,pidfile =.*,pidfile = "/run/lava-coordinator/lava-coordinator.pid",' /usr/bin/lava-coordinator

EXPOSE 3079 5555 5556

CMD /root/entrypoint.sh && while [ true ]; do sleep 365d; done

