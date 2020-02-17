# Use LSIO Ubuntu Bionic version
FROM lsiobase/ubuntu:bionic

# Latest VMS versions are listed here:
# https://dwspectrum.digital-watchdog.com/download/linux
# https://nxvms.com/download/linux
ARG DOWNLOAD_URL="http://updates.networkoptix.com/digitalwatchdog/29990/linux/dwspectrum-server-4.0.0.29990-linux64.deb"
ARG DOWNLOAD_VERSION="4.0.0.29990"

# Prevent EULA and confirmation prompts in installers
ENV DEBIAN_FRONTEND=noninteractive \
# NxWitness or DWSpectrum
    COMPANY_NAME="digitalwatchdog"

LABEL name="DWSpectrum-LSIO" \
    version=${DOWNLOAD_VERSION} \
    download=${DOWNLOAD_URL} \
    description="DW Spectrum IPVMS Docker based on LinuxServer" \
    maintainer="Pieter Viljoen <ptr727@users.noreply.github.com>"

# Install dependencies
RUN apt-get update \
    && apt-get install --yes \
# Install wget so we can download the installer
        wget \
# Install nano and mc for making navigating the container easier
        nano mc \
# Install gdb for crash handling (it is used but not included in the deb dependencies)
        gdb gdbserver \
# Install binutils for patching cloud host (from nxwitness docker)
        binutils \
# Install lsb-release used as a part of install scripts inside the deb package (from nxwitness docker)
        lsb-release \
# Download the DEB installer file
    && wget -nv -O ./vms_server.deb ${DOWNLOAD_URL} \
#
# DEB and LSIO modification logic is based on https://github.com/thehomerepot/nxwitness/blob/master/Dockerfile
# Replace the LSIO abc usernames with the mediaserver names
# https://github.com/linuxserver/docker-baseimage-alpine/blob/master/root/etc/cont-init.d/10-adduser
    && usermod -l ${COMPANY_NAME} abc \
    && groupmod -n ${COMPANY_NAME} abc \
    && sed -i "s/abc/\${COMPANY_NAME}/g" /etc/cont-init.d/10-adduser \
# Extract the DEB file so we can modify it before installing
    && dpkg-deb -R ./vms_server.deb ./vms_server \
# Remove the systemd depency from the dependencies list
# Before: psmisc, systemd (>= 229), cifs-utils
# After: psmisc, cifs-utils
# sed -i 's/systemd.*), //' ./extracted/DEBIAN/control && \
    && sed -i 's/systemd.*), //' ./vms_server/DEBIAN/control \
# Remove all instructions detailing crash reporting (all text after the "Dirty hack to prevent" line is removed from file)
# sed -i '/# Dirty hack to prevent/q' ./extracted/DEBIAN/postinst && \
    && sed -i '/# Dirty hack to prevent/q' ./vms_server/DEBIAN/postinst \
# Remove the result of systemctl
# Before: systemctl stop $COMPANY_NAME-mediaserver || true
# Before: systemctl stop $COMPANY_NAME-root-tool || true
# After: systemctl stop $COMPANY_NAME-mediaserver 2>/dev/null || true
# After: systemctl stop $COMPANY_NAME-root-tool 2>/dev/null || true
# sed -i "/systemctl.*stop/s/ ||/ 2>\/dev\/null ||/g" ./extracted/DEBIAN/postinst && \
    && sed -i "/systemctl.*stop/s/ ||/ 2>\/dev\/null ||/g" ./vms_server/DEBIAN/postinst \
# Remove the runtime detection logic that uses systemd-detect-virt
# Before: local -r runtime=$(systemd-detect-virt)
# After: local -r runtime=$(echo "none")
# sed -i 's/systemd-detect-virt/echo "none"/' ./extracted/DEBIAN/postinst && \
    && sed -i 's/systemd-detect-virt/echo "none"/' ./vms_server/DEBIAN/postinst \    
# Remove su and chuid from start logic
# Before: su digitalwatchdog -c 'ulimit -c unlimited; ulimit -a'
# Before: --chuid digitalwatchdog:digitalwatchdog \
# After: Blank lines
# sed -i '/^    su/d; /--chuid/d' ./extracted/opt/${COMPANY_NAME}/mediaserver/bin/mediaserver && \
    && sed -i '/^    su/d; /--chuid/d' ./vms_server/opt/${COMPANY_NAME}/mediaserver/bin/mediaserver \
# Remove all the etc/init and etc/systemd folders
    && rm -rf ./vms_server/etc \
#
# Rebuild the DEB file from the modified directory
    && dpkg-deb -b ./vms_server ./vms_server_mod.deb \
# Install from the modified DEB file
    && apt-get install -y ./vms_server_mod.deb \
# Cleanup    
    && rm -rf ./vms_server \
    && rm -rf ./vms_server.deb \
    && rm -rf ./vms_server_mod.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy etc init and services files
# The scripts are using the ${COMPANY_NAME} global environment variable
# https://github.com/just-containers/s6-overlay#container-environment
COPY root/etc /etc

# Expose port 7001
EXPOSE 7001

# Create mount points
# Links will be created at runtime in the etc/cont-init.d/50-relocate-files script
# /opt/digitalwatchdog/mediaserver/etc -> /config/etc
# /opt/digitalwatchdog/mediaserver/var -> /config/var
# /opt/digitalwatchdog/mediaserver/var/data -> /media
VOLUME /config /media
