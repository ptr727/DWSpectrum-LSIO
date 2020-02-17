# DW Spectrum IPVMS Docker

This is a docker project for the [DW Spectrum IPVMS](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/).  
DW Spectrum is the US licensed version of [NetworkOptix Nx Witness VMS](https://www.networkoptix.com/nx-witness/).  

This project is based on the NetworkOptix [docker project](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/).  
There are a few key problems with the NetworkOptix docker project:

- The container uses `systemd` and runs as `root` and does not work in some docker environments like [Unraid](https://unraid.net).
- The docker build script is external to the dockerfile and does not work in automated build enviorments like [Docker Hub](https://docs.docker.com/docker-hub/builds/).

This project modifes the NetworkOptix version to run as `init`, to build from within the `Dockerfile`, and to automatically post builds on Docker Hub.  
Modifications to replace `systemd` with `init`, and to use [LinuxServer](https://www.linuxserver.io) and [s6-overlay](https://github.com/just-containers/s6-overlay), are based on [The Home Repot NxWitness](https://github.com/thehomerepot/nxwitness) project.  

An [alternate version](https://github.com/ptr727/DWSpectrum) is based on the original NetworkOptix `systemd` docker configuration using an Ubuntu base image.

## License

![GitHub](https://img.shields.io/github/license/ptr727/DWSpectrum-LSIO)  

## Build Status

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/ptr727/dwspectrum-lsio?logo=docker)  
Pull from [Docker Hub](https://hub.docker.com/r/ptr727/dwspectrum-lsio)  
Code at [GitHub](https://github.com/ptr727/DWSpectrum)

## Usage

### Docker Run Example

```shell
docker run -d \
  --name=dwspectrum-lsio-test-container \
  --restart=unless-stopped \
  --network=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Americas/Los_Angeles \
  -v /.mount/media:/media \
  -v /.mount/config:/config \
  ptr727/dwspectrum-lsio
```

### Docker Compose Example

```yaml
version: "3.7"

services:
  dwspectrum:
    image: ptr727/dwspectrum-lsio
    container_name: dwspectrum-lsio-test-container
    hostname: dwspectrum-lsio-test-host
    domainname: foo.net
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Americas/Los_Angeles
    volumes:
      - ./.mount/media:/media
      - ./.mount/config:/config
    restart: unless-stopped
    network_mode: host
    mac_address: b7-48-d5-a6-d1-99
    ports:
      - 7001:7001
```

## Notes

- This project is experimental, the NetworkOptix code does not behave well in docker environments.
- The camera licenses are tied to server hardware information that may change in container hosting environments. For some portability set a fixed container MAC address using e.g. `mac_address: aa-bb-cc-dd-ee-ff` in the compose file.
- The [LSIO](https://docs.linuxserver.io/general/understanding-puid-and-pgid) base image allows us to specify PUID, GUID, and TZ environment variables. This allows the container to run as non-root with appropriate permissions for mapped volumes.
- The container volumes are `/media` and `/config`, the networkserver paths are re-linked at runtime in the `etc/cont-init.d/50-relocate-files` script.

## NetworkOptix Issues

- The mediaserver [filters](https://support.networkoptix.com/hc/en-us/requests/19037) out mapped storage locations, and does not allow the user to specify desired storage locations.
  - Warning message in the logs: `QnStorageManager(0x7f863c054bd0): No storage available for recording`.
  - No mapped storage is detected on [Unraid](https://unraid.net).
  - The behavior on [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) appears to be random, sometimes a storage location is detected, other times nothing.
  - Per NetworkOptix support, only the following filesystems are currently supported: `vfat, ecryptfs, fuseblk, fuse, fusectl, xfs, ext3, ext2, ext4, exfat, rootfs, nfs, nfs4, nfsd, cifs, fuse.osxfs`.
  - `cat /proc/mounts` for a few filesystems I tested, note that neither `fuse.grpcfuse` nor `fuse.shfs` is in the supported list:
    - Unraid : `shfs /media fuse.shfs rw,nosuid,nodev,noatime,user_id=0,group_id=0,allow_other 0 0`
    - Docker Desktop for Windows : `grpcfuse /media fuse.grpcfuse rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576 0 0`
    - Docker on Ubuntu Server : `/dev/vda2 /media ext4 rw,relatime,data=ordered 0 0`
  - In Ubuntu Server, with a [non-root user](https://docs.docker.com/install/linux/linux-postinstall/), we get a runtime failure: `start-stop-daemon: unable to start /opt/digitalwatchdog/mediaserver/bin/mediaserver-bin (Invalid argument)`.
  - The calculation of `VMS_DIR=$(dirname $(dirname "${BASH_SOURCE[0]}"))` in `../bin/mediaserver` results in bad paths e.g. `start-stop-daemon: unable to stat ./bin/./bin/mediaserver-bin (No such file or directory)`.
  - The DEB installer does not reference all used dependencies. When trying to minimizing the size of the install by using `--no-install-recommends` we get a `OCI runtime create failed` error. We have to manually add the following required dependencies: `gdb gdbserver binutils lsb-release`.
- [Convince](https://support.networkoptix.com/hc/en-us/articles/360037973573-How-to-run-Nx-Server-in-Docker) NetworkOptix to:
  - Live up to the [purpose](https://www.docker.com/why-docker) of docker;  make app deployments easy.
  - Publish always up to date ready to use docker images to Docker Hub.
  - Use the cloud account for license enforcement, not the hardware that dynamically changes in docker environments.
  - Create `init` based images instead of less portable `systemd` based images.
  - Allow using any path or volume to be used for storage instead of incorrectly filtering our locations.

## TODO

- Automatically detect new [NxWitness](https://nxvms.com/download/linux) or [DWSpectrum](https://dwspectrum.digital-watchdog.com/download/linux) releases and update the container. Possibly parsing the readme file for version information, and using a webhook to kick the build.
