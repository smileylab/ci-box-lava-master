## Prerequisite

- docker
- docker-compose

## Build you container image

   [sudo] make

## Start image

   [sudo] make run

## Play

The configuration can be customized via docker-compose.yml file.
By default lava-server web interface is exposed to port 5580 (localhost:5580).
This is a lava-server only instance (not worker), it expects a worker0 dispatcher.
By default two qemu devices are automatically added via overlays.

# IMPORTANT NOTICE

The ci-box-lava-master does not follow Loic Poulain ci-box docker container anymore.

It is now based on docker container from https://github.com/kernelci/lava-docker.git

* configs are configuration files copied into the docker container, configuration files are modified by ../ci-box-gen.py
* entrypoint.d contains startup scripts and is copied into the docker container, lava-master will start and run these scripts
* lava-patch folder contains any patch files that is necessary to modify the lava-master python source code
* overlays folder is no longer needed

