# DW Spectrum IPVMS Docker

[DW Spectrum IPVMS](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/) is the US branded version of [Network Optix Nx Witness VMS](https://www.networkoptix.com/nx-witness/).  
The docker configuration is based on the [NetworkOptix Docker](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/) project.  
The base image is [LinuxServer Ubuntu](https://hub.docker.com/r/lsiobase/ubuntu), where we can specify the UID, GID, and TZ, allowing is to run as non-root, and using the correct user rights for mapped data volumes.  
The systemd removal modifications, and adoption for LSIO, is based on [The Home Repot NxWitness Docker](https://github.com/thehomerepot/nxwitness) project.  
An [alternate version](https://github.com/ptr727/DWSpectrum) is based on an Ubuntu base image and runs as systemd.

## License

![GitHub](https://img.shields.io/github/license/ptr727/DWSpectrum-LSIO)  

## Build Status

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/ptr727/dwspectrum-lsio)  
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
    ports:
      - 7001:7001
```

## Notes

- The camera licenses are tied to hardware information, and this does not work well in container environments where the hardware may change.  
- The modifications to remove systemd and make LSIO work is documented in the Dockerfile, and are based on [The Home Repot NxWitness](https://github.com/thehomerepot/nxwitness) modifications.
- Use a UID and GUID that has rights on the the mapped data volumes, see the [LSIO docs](https://docs.linuxserver.io/general/understanding-puid-and-pgid) for more details.  
- By using the LSIO images we can specify PUID, GUID, and TZ environment variables, ideal when using UnRaid.

## TODO

- The container does run in Unraid, but no storage volumes are available in the VMS. This appears to be an issue with supported filesystem types, and needs to be [resolved](https://support.networkoptix.com/hc/en-us/requests/19037) by NetworkOptix.
- [Convince](https://support.networkoptix.com/hc/en-us/articles/360037973573-How-to-run-Nx-Server-in-Docker) NxWitness to:
  - Publish always up to date docker images to Docker Hub.
  - Use the cloud account for license enforcement, not the hardware that dynamically changes in Docker environments.
  - Convert their Docker deployment to not use systemd, alleviating the need for "hacking" the install.
- Figure out how to automatically detect when new [NxWitness](https://nxvms.com/download/linux) or [DWSpectrum](https://dwspectrum.digital-watchdog.com/download/linux) releases are published, and update the container. Possibly parsing the readme file for version information, and using a webhook to kick the build.
- Figure out how to use `--no-install-recommends` to make the image smaller. Currently we get a `OCI runtime create failed` error if it is used, probably missing some required but unspecified dependencies.
- Resolve runtime failure `start-stop-daemon: unable to start /opt/digitalwatchdog/mediaserver/bin/mediaserver-bin (Invalid argument)`. It also happens with the base NxWitness container, but does not happen in all environments.
- Using the lsiobase/ubuntu:xenial base image results in an [systemd-detect-virt error](https://github.com/systemd/systemd/issues/8111), the ubuntu:xenial base does not have the same problem, so we use lsiobase/ubuntu:bionic builds.
