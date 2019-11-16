# DW Spectrum IPVMS Docker

[DW Spectrum IPVMS](https://digital-watchdog.com/productdetail/DW-Spectrum-IPVMS/) is the US version of [Network Optix Nx Witness VMS](https://www.networkoptix.com/nx-witness/).  
The docker configuration is based on the [NetworkOptix Docker](https://bitbucket.org/networkoptix/nx_open_integrations/src/default/docker/) project.  
The base image is [LinuxServer Ubuntu](https://hub.docker.com/r/lsiobase/ubuntu), where we can specify the UID, GID, and TZ, allowing is to run as non-root, and using the correct user rights for mapped data volumes.  
The systemd removal modifications, and adoption for LSIO, is based on [The Home Repot NxWitness Docker](https://github.com/thehomerepot/nxwitness) project.  
An [alternate version](https://github.com/ptr727/DWSpectrum) is based on an Ubuntu base image and runs as systemd.

## License

![GitHub](https://img.shields.io/github/license/ptr727/DWSpectrum-LSIO)  

## Build Status

![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/ptr727/dwspectrum-lsio)
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
  -v "/.mount/media:/config/DW Spectrum Media" \
  -v /.mount/config:/opt/digitalwatchdog/mediaserver/var \
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
    volumes:
      - ./.mount/media:/config/DW Spectrum Media
      - ./.mount/config/:/opt/digitalwatchdog/mediaserver/var
    restart: unless-stopped
    network_mode: host
    ports:
      - 7001:7001
```

## Notes

- The camera licenses are tied to hardware information, and this does not work well in container environments where the hardware may change.  
- Use a UID and GUID that has rights on the the mapped data volumes, see the [LSIO docs](https://docs.linuxserver.io/general/understanding-puid-and-pgid) for more details.  
- Using the lsiobase/ubuntu:xenial base image results in an [systemd-detect-virt error](https://github.com/systemd/systemd/issues/8111), the ubuntu:xenial base does not have the same problem, so we use lsiobase/ubuntu:bionic builds, which works fine.
- By using the LSIO images we can specify PUID, GUID, and TZ environment variables, ideal when using UnRaid.
- The NxWitness docker setup uses systemd, which as far as I researched (and I am not an expert in this field), is not recommended in docker. It is [possible](https://developers.redhat.com/blog/2019/04/24/how-to-run-systemd-in-a-container/) to run systemd in docker, but it does not work in LSIO (and again I'm no LSIO expert either).
- The modifications to remove systemd and make LSIO work is documented in the Dockerfile, and are based on [The Home Repot NxWitness](https://github.com/thehomerepot/nxwitness) modifications.

## TODO

- Automatically detect when new releases are published, and automatically update the container. It would really help if NxWitness were to publish a latest link in a generic form, or on a page making link parsing easy. Today we have to look at the details of the [NxWitness](https://nxvms.com/download/linux) or [DWSpectrum](https://dwspectrum.digital-watchdog.com/download/linux) cloud pages.
- [Convince](https://support.networkoptix.com/hc/en-us/articles/360037973573-How-to-run-Nx-Server-in-Docker) NxWitness to publish always up to date docker images, that allow specifying the user account to run under, and with licenses tied to the cloud account, so that we would not have to build and publish our own containers, and deal with hardware changes invalidating the camera licenses.
