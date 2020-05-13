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
Code at [GitHub](https://github.com/ptr727/DWSpectrum)

## Usage

### Docker Run Example

```console
docker run -d \
  --name=dwspectrum-lsio-test-container \
  --restart=unless-stopped \
  --network=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Americas/Los_Angeles \
  -v /.mount/config:/config \
  -v /.mount/media:/media \
  -v /.mount/archive:/archive \
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
      - ./.mount/config:/config
      - ./.mount/media:/media
      - ./.mount/archive:/archive
    restart: unless-stopped
    network_mode: host
    mac_address: b7-48-d5-a6-d1-99
    ports:
      - 7001:7001
```

### Unraid Docker Template

- Add the template URL `https://github.com/ptr727/DWSpectrum-LSIO/tree/master/Unraid` to the Docker "Template Repositories" section and click "Save".
- Create a new container by clicking the "Add Container" button, select "DWSpectrum-LSIO" from the Template dropdown.
- Set the required volume mappings, if mapping to a disk or NFS share, set the access mode to "RW/Slave".
- Set the network mode to bridge and enter the desired server static IP address.

## Notes

- Docker support is [experimental](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/), the NetworkOptix code does not behave well in docker environments.
- The camera licenses are tied to server hardware information that may [become invalid](https://support.networkoptix.com/hc/en-us/articles/360036141153-HWID-changed-and-license-is-no-longer-recording) in container hosting environments. For some portability try to set a fixed container MAC address using e.g. `mac_address: aa-bb-cc-dd-ee-ff` in the compose file. In my experience this is not sufficient to retain license validity, but your experience may differ.
- The [LSIO](https://docs.linuxserver.io/general/understanding-puid-and-pgid) base image allows us to specify PUID, GUID, and TZ environment variables. This allows the container to run as non-root with appropriate permissions for mapped volumes.
- The container volumes are `/media` for recordings, `/archive` for backups, and `/config` for configuration.
- The networkserver install paths are re-linked at runtime to the mapped volumes in the `etc/cont-init.d/50-relocate-files` script.

## NetworkOptix Issues

- The mediaserver [filters](https://support.networkoptix.com/hc/en-us/requests/19037) mapped storage volumes by filesystem type, and does not allow the admin to specify desired storage locations. E.g neither BTRFS nor ZFS are "supported" filesystems.
  - Look for warning messages in the logs, e.g. `QnStorageManager(0x7f863c054bd0): No storage available for recording`.
  - Because of filesystem type filtering, no mapped media storage is detected on [Unraid](https://unraid.net), and workarounds are required:
    - Use the [Unassigned Devices](https://forums.unraid.net/topic/44104-unassigned-devices-managing-disk-drives-and-remote-shares-outside-of-the-unraid-array/) plugin, and map the volume to the unassigned device, formatted as XFS, and mounted using `RW/Slave` access mode.
    - Create a NFS share on the Unraid server, mount the NFS share on that same server, and map the volume to the NFS share, using `RW/Slave` access mode. The mediaserver will use the NFS volume regardless of the backing filesystem type. If the NFS server is on the local machine, consider reducing the NFS security scope to `127.0.0.1(rw)`.
    - In my experience it works well to use a SSD for the `/media` volume for direct recording, and the NFS `/archive` volume for recording backups.
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
  - Live up to the [purpose](https://www.docker.com/why-docker) of docker and make app deployments easy.
  - Publish always up to date and ready to use docker images on Docker Hub.
  - Use the cloud account for license enforcement, not the hardware that dynamically changes in docker environments.
  - Create broadly compatible `init` based images instead of less portable `systemd` based images.
  - Allow the administrator to use any path or volume for storage.
