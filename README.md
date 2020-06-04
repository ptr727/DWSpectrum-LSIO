# DW Spectrum IPVMS Docker

This is a docker project for the [Digital Watchdog DW Spectrum IPVMS](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/).  
DW Spectrum is the US licensed and branded version of [Network Optix Nx Witness VMS](https://www.networkoptix.com/nx-witness/).  
The image is based on [LinuxServer](https://www.linuxserver.io/) using a [lsiobase/ubuntu:bionic](https://hub.docker.com/r/lsiobase/ubuntu) base image.

## License

![GitHub](https://img.shields.io/github/license/ptr727/DWSpectrum-LSIO)  

## Build Status

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/ptr727/dwspectrum-lsio?logo=docker)  
Pull from [Docker Hub](https://hub.docker.com/r/ptr727/dwspectrum-lsio)  
Code at [GitHub](https://github.com/ptr727/DWSpectrum-LSIO)

## Overview

I maintain Docker projects for two Network Optix products, using two base images.  
I try to keep the implementation in sync with the Network Optix [reference docker project](https://github.com/networkoptix/nx_open_integrations/tree/master/docker).  
The Network Optix development team is receptive to feedback, and has made several improvements in support of Docker.  
The biggest outstanding Docker challenges are hardware bound licensing, and lack of admin defined storage locations.

### Products

- [Nx Meta](https://meta.nxvms.com/) is the developer preview version of [Nx Witness](https://www.networkoptix.com/nx-witness/). I use Nx Meta to test upcoming product features or changes.
- [DW Spectrum](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/) is the US OEM version of [Nx Witness](https://www.networkoptix.com/nx-witness/). I am based in the US, and I have to use the [Digital Watchdog](https://digital-watchdog.com/) licensed version in production.

Note, for a Nx Witness container, see [The Home Repot](https://github.com/thehomerepot/nxwitness) project.

### Base Images

- [Ubuntu](https://ubuntu.com/) using [ubuntu:bionic](https://hub.docker.com/_/ubuntu) base image.
- [LinuxServer](https://www.linuxserver.io/) using [lsiobase/ubuntu:bionic](https://hub.docker.com/r/lsiobase/ubuntu) base image.

Note, I can use smaller base images like [alpine](https://hub.docker.com/_/alpine), but the mediaserver officially [supports](https://support.networkoptix.com/hc/en-us/articles/205313168-Nx-Witness-Operating-System-Support) Ubuntu Bionic.

### Projects

- [NxMeta](https://github.com/ptr727/NxMeta): NxMeta using `ubuntu:bionic`.
- [NxMeta-LSIO](https://github.com/ptr727/NxMeta-LSIO): NxMeta using `lsiobase/ubuntu:bionic`.
- [DWSpectrum](https://github.com/ptr727/DWSpectrum): DW Spectrum using `ubuntu:bionic`.
- [DWSpectrum-LSIO](https://github.com/ptr727/DWSpectrum-LSIO): DW Spectrum using `lsiobase/ubuntu:bionic`.

### LinuxServer

- The [LinuxServer (LSIO)](https://www.linuxserver.io/) images are based on [s6-overlay](https://github.com/just-containers/s6-overlay), and LSIO [produces](https://fleet.linuxserver.io/) containers for many popular open source apps.
- LSIO allows us to [specify](https://docs.linuxserver.io/general/understanding-puid-and-pgid) the user account to use when running the container process.
- This is [desired](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user) if we do not want to run as root, or required if we need user specific permissions when accessing mapped volumes.
- We could achieve a similar outcome by using Docker's [--user](https://docs.docker.com/engine/reference/run/#user) or [USER](https://docs.docker.com/engine/reference/builder/#user) options, but it is often more convenient to modify environment variables vs. controlling how a container runs.

### Unraid

- I run [Unraid](https://unraid.net/) in my home lab, as such I need the containers to work in an Unraid environment.
- The LSIO images work well on Unraid, because I can specify user permissions for mapped shares, and I save some space because layers are shared between several other LSIO based images I run.
- I include [Unraid Docker Templates](./Unraid) simplifying provisioning on Unraid.
- There are still Nx Witness issues when using Unraid user shares for storage, see the various notes sections.

## Configuration

### Volumes

`/config` : Configuration files.  
`/media` : Recording files.  
`/archive` : Backup files. (Optional)

Note, the current Nx Witness backup implementation is [not very useful](https://support.networkoptix.com/hc/en-us/community/posts/360044221713-Backup-retention-policy), as it only makes a copy of the recordings, it does not extend the retention period.

Note, the mediaserver filters [filesystems](https://github.com/networkoptix/nx_open_integrations/tree/master/docker#notes-about-storage) by type, and the `/media` mapping must point to a supported filesytem. The upcoming version 4.1 [will support](https://support.networkoptix.com/hc/en-us/community/posts/360044241693-NxMeta-4-1-Beta-on-Docker) user defined filesystems. Unraid's FUSE filesystem is not supported, and requires the mapping of a physical device using the [Unassigned Devices](https://forums.unraid.net/topic/44104-unassigned-devices-managing-disk-drives-and-remote-shares-outside-of-the-unraid-array/) plugin.  
Unfortunately, or unfathomably, admin defined storage is not supported, and the mediaserver insists on getting in the way.

### Ports

`7001` : Default server port.

### Environment Variables

`PUID` : User Id (LSIO only, see [docs](https://docs.linuxserver.io/general/understanding-puid-and-pgid) for usage).  
`PGID` : Group Id (LSIO only).  
`TZ` : Timezone, e.g. `Americas/Los_Angeles`.

### Network Mode

Any network mode can be used, but due to the hardware bound licensing, `host` mode is [preferred](https://github.com/networkoptix/nx_open_integrations/tree/master/docker#networking).

## Examples

### Docker Create

```console
docker create \
  --name=dwspectrum-lsio-test-container \
  --hostname=dwspectrum-lsio-test-host \
  --domainname=foo.bar.net \
  --restart=unless-stopped \
  --network=host \
  --env TZ=Americas/Los_Angeles \
  --volume /mnt/dwspectrum/config:/config:rw \
  --volume /mnt/dwspectrum/media:/media:rw \
  ptr727/dwspectrum-lsio

docker start dwspectrum-lsio-test-container
```

### Docker Compose

```yaml
version: "3.7"

services:
  dwspectrum:
    image: ptr727/dwspectrum-lsio
    container_name: dwspectrum-lsio-test-container
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Americas/Los_Angeles
    volumes:
      - /mnt/dwspectrum/config:/config
      - /mnt/dwspectrum/media:/media
```

### Unraid Template

- Add the template [URL](./Unraid) `https://github.com/ptr727/DWSpectrum-LSIO/tree/master/Unraid` to the "Template Repositories" section, at the bottom of the "Docker" configuration tab, and click "Save".
- Use the [Unassigned Devices](https://forums.unraid.net/topic/44104-unassigned-devices-managing-disk-drives-and-remote-shares-outside-of-the-unraid-array/) plugin and mount a SSD drive formatted as XFS. This is currently a required workaround for the mediaserver filesystem filtering.
- Create a new container by clicking the "Add Container" button, select "DWSpectrumLSIO" from the Template dropdown.
- Map the Unassigned Device SSD drive to the `/media` volume, using `RW/Slave` access mode.

## Notes

The following applies to the [current](http://beta.networkoptix.com/beta-builds/default/#patches_list) (as of writing) version 4.0.0.30917:

- The mediaserver filters mapped storage volumes by filesystem type, and does not allow the admin to specify desired storage locations.
  - Look for warning messages in the logs, e.g. `QnStorageManager(0x7f863c054bd0): No storage available for recording`.
  - Because of filesystem type filtering, no mapped media storage is detected on [Unraid](https://unraid.net), [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop), or [ZFS](https://zfsonlinux.org/) storage volumes.
  - Per Network Optix support, only the following filesystems are currently supported: `vfat, ecryptfs, fuseblk, fuse, fusectl, xfs, ext3, ext2, ext4, exfat, rootfs, nfs, nfs4, nfsd, cifs, fuse.osxfs`.
  - Output from `cat /proc/mounts` for a few filesystems I tested:
    - Unraid : `shfs /media fuse.shfs rw,nosuid,nodev,noatime,user_id=0,group_id=0,allow_other 0 0`
    - Docker Desktop for Windows : `grpcfuse /media fuse.grpcfuse rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576 0 0`
    - Docker on Ubuntu Server EXT4 : `/dev/vda2 /media ext4 rw,relatime,data=ordered 0 0`
    - Docker on Proxmox ZFS : `ssdpool/dwspectrum/media /media zfs rw,noatime,xattr,posixacl 0 0`
- In Ubuntu Server, with a [non-root user](https://docs.docker.com/install/linux/linux-postinstall/), we get a runtime failure: `start-stop-daemon: unable to start /opt/digitalwatchdog/mediaserver/bin/mediaserver-bin (Invalid argument)`.
- The calculation of `VMS_DIR=$(dirname $(dirname "${BASH_SOURCE[0]}"))` in `../bin/mediaserver` results in bad paths e.g. `start-stop-daemon: unable to stat ./bin/./bin/mediaserver-bin (No such file or directory)`.
- The DEB installer does not reference all used dependencies. When trying to minimizing the size of the install by using `--no-install-recommends` we get a `OCI runtime create failed` error. We have to manually add the following required dependencies: `gdb gdbserver binutils lsb-release`.

## Network Optix Wishlist

Network Optix wishlist for better [docker support](https://support.networkoptix.com/hc/en-us/articles/360037973573-How-to-run-Nx-Server-in-Docker):

- Publish always up to date and ready to use docker images on Docker Hub.
- Use the cloud account for license enforcement, not the hardware that dynamically changes in docker environments.
- Allow the administrator to specify and use any storage location, stop making incorrect automated storage decisions.
- Implement a [more useful](https://support.networkoptix.com/hc/en-us/community/posts/360044221713-Backup-retention-policy) recording archive management system, allowing for separate high speed recording, and high capacity playback storage volumes.
