# DW Spectrum IPVMS Docker

This is a docker project for the [DW Spectrum IPVMS](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/).  
DW Spectrum is the US licensed version of [NetworkOptix Nx Witness VMS](https://www.networkoptix.com/nx-witness/).  

This project is based on the NetworkOptix [docker project](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/).  
There are a few key problems with the NetworkOptix docker project:

- The container uses `systemd` and runs as `root` and does not work in some docker environments like [Unraid](https://unraid.net).
- The docker build script is external to the dockerfile and does not work in automated build environments like [Docker Hub](https://docs.docker.com/docker-hub/builds/).

This project modifies the NetworkOptix version to run as `init`, to build from within the `Dockerfile`, and to automatically post builds on Docker Hub.  
Modifications to replace `systemd` with `init`, and to use [LinuxServer](https://www.linuxserver.io) and [s6-overlay](https://github.com/just-containers/s6-overlay), are based on [The Home Repot NxWitness](https://github.com/thehomerepot/nxwitness) project.  

An [alternate version](https://github.com/ptr727/DWSpectrum) is based on the original NetworkOptix `systemd` docker configuration using an Ubuntu base image.

## License

![GitHub](https://img.shields.io/github/license/ptr727/DWSpectrum-LSIO)  

## Build Status

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/ptr727/dwspectrum-lsio?logo=docker)  
Pull from [Docker Hub](https://hub.docker.com/r/ptr727/dwspectrum-lsio)  
Code at [GitHub](https://github.com/ptr727/DWSpectrum-LSIO)

## Usage

### Docker Example

```console
docker network create --driver macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 --opt parent=eth0 dwspectrum-macvlan

docker create \
  --name=dwspectrum-lsio-test-container \
  --hostname=dwspectrum-lsio-test-host \
  --domainname=foo.bar.net \
  --restart=unless-stopped \
  --network=dwspectrum-nacvlan \
  --ip=192.168.1.100 \
  --mac-address=07:58:8a:fc:30:e5 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Americas/Los_Angeles \
  -v /mnt/dwspectrum/config:/config:rw \
  -v /mnt/dwspectrum/media:/media:rw \
  -v /mnt/dwspectrum/archive:/archive:rw \
  ptr727/dwspectrum-lsio

docker start dwspectrum-lsio-test-container
```

### Compose Example

The YAML version must be set to "2.1" for `macvlan` networks, else you may encounter a `gateway is unexpected` error:

```yaml
version: "2.1"

services:
  dwspectrum:
    image: ptr727/dwspectrum-lsio
    container_name: dwspectrum-lsio-test-container
    hostname: dwspectrum-lsio-test-host
    domainname: foo.bar.net
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Americas/Los_Angeles
    volumes:
      - /mnt/dwspectrum/config:/config
      - /mnt/dwspectrum/media:/media
      - /mnt/dwspectrum/archive:/archive
    restart: unless-stopped
    ports:
      - 7001:7001
    mac_address: 07:58:8a:fc:30:e5
    networks:
      dwspectrum-macvlan:
        ipv4_address: 192.168.1.100

networks:
  dwspectrum-macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      driver: default
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
```

A simplified `bridge` mode configuration:

```yaml
version: "3.7"

services:
  dwspectrum:
    image: ptr727/dwspectrum-lsio
    container_name: dwspectrum-lsio-test-container
    environment:
      - TZ=Americas/Los_Angeles
    volumes:
      - /mnt/dwspectrum/config:/config
      - /mnt/dwspectrum/media:/media
    restart: unless-stopped
    ports:
      - 7001:7001
    network_mode: bridge
```

### Unraid Docker Template

- Add the template URL `https://github.com/ptr727/DWSpectrum-LSIO/tree/master/Unraid` to the Docker "Template Repositories" section and click "Save".
- Create a new container by clicking the "Add Container" button, select "DWSpectrum-LSIO" from the Template dropdown.
- Set the network type to custom, select the bridged (macvlan) adapter, and enter the desired server static IP address.
- [Create](https://miniwebtool.com/mac-address-generator/) a unique MAC address, and enter it in the "Extra Parameters" section, e.g. `--mac-address=07:58:8a:fc:30:e5`.
- Use the [Unassigned Devices](https://forums.unraid.net/topic/44104-unassigned-devices-managing-disk-drives-and-remote-shares-outside-of-the-unraid-array/) plugin and mount a SSD drive formatted as XFS, and map the SSD drive to the `/media` volume mounted using `RW/Slave` access mode.
- If required, mount a NFS share, and map the NFS mount to the `/archive` volume using `RW/Slave` access mode.

## Notes

- Docker support is still [experimental](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/), the NetworkOptix code does not always behave well in docker environments.
- The camera licenses are tied to server hardware information that may [become invalid](https://support.networkoptix.com/hc/en-us/articles/360036141153-HWID-changed-and-license-is-no-longer-recording) in container hosting environments when using dynamic networks. For some portability use a `macvlan` network and set a fixed container MAC address using the `--mac-address=` option.
- The [LSIO](https://docs.linuxserver.io/general/understanding-puid-and-pgid) base image allows us to specify PUID, GUID, and TZ environment variables. This allows the container to run as non-root with appropriate permissions for mapped volumes.
- The container volumes are `/media` for recordings, `/archive` for backups, and `/config` for configuration.
- The networkserver install paths are re-linked at runtime to the mapped volumes in the `etc/cont-init.d/50-relocate-files` script.

## NetworkOptix Issues

- The mediaserver [filters](https://support.networkoptix.com/hc/en-us/requests/19037) mapped storage volumes by filesystem type, and does not allow the admin to specify desired storage locations. E.g neither BTRFS nor ZFS are "supported" filesystems.
  - Look for warning messages in the logs, e.g. `QnStorageManager(0x7f863c054bd0): No storage available for recording`.
  - Because of filesystem type filtering, no mapped media storage is detected on [Unraid](https://unraid.net), and workarounds are required, see the Unraid section above.
  - As with Unraid, [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) strorage volumes are not detected, I have not yet found a workaround.
  - Per NetworkOptix support, only the following filesystems are currently supported: `vfat, ecryptfs, fuseblk, fuse, fusectl, xfs, ext3, ext2, ext4, exfat, rootfs, nfs, nfs4, nfsd, cifs, fuse.osxfs`.
  - Output from `cat /proc/mounts` for a few filesystems I tested, note that neither `fuse.grpcfuse` nor `fuse.shfs` is in the supported list:
    - Unraid : `shfs /media fuse.shfs rw,nosuid,nodev,noatime,user_id=0,group_id=0,allow_other 0 0`
    - Docker Desktop for Windows : `grpcfuse /media fuse.grpcfuse rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576 0 0`
    - Docker on Ubuntu Server : `/dev/vda2 /media ext4 rw,relatime,data=ordered 0 0`
- In Ubuntu Server, with a [non-root user](https://docs.docker.com/install/linux/linux-postinstall/), we get a runtime failure: `start-stop-daemon: unable to start /opt/digitalwatchdog/mediaserver/bin/mediaserver-bin (Invalid argument)`.
- The calculation of `VMS_DIR=$(dirname $(dirname "${BASH_SOURCE[0]}"))` in `../bin/mediaserver` results in bad paths e.g. `start-stop-daemon: unable to stat ./bin/./bin/mediaserver-bin (No such file or directory)`.
- The DEB installer does not reference all used dependencies. When trying to minimizing the size of the install by using `--no-install-recommends` we get a `OCI runtime create failed` error. We have to manually add the following required dependencies: `gdb gdbserver binutils lsb-release`.
- There is no real support for recording archive management, as backup volumes are simply copies of the media volume, i.e. there is no value in using backups to extend recording retention capacity.
- [Convince](https://support.networkoptix.com/hc/en-us/articles/360037973573-How-to-run-Nx-Server-in-Docker) NetworkOptix to:
  - Live up to the [purpose](https://www.docker.com/why-docker) of docker and make app deployments easy.
  - Publish always up to date and ready to use docker images on Docker Hub.
  - Use the cloud account for license enforcement, not the hardware that dynamically changes in docker environments.
  - Create broadly compatible `init` based images instead of less portable `systemd` based images.
  - Allow the administrator to use any path or volume for storage.
  - [Create](https://support.networkoptix.com/hc/en-us/community/posts/360044221713-Backup-retention-policy) a more useful recording archive management system allowing for separate high speed low capacity media recording, and slower high capacity media playback storage volumes.
