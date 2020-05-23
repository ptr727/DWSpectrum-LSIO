# Use LSIO Ubuntu Bionic version
FROM lsiobase/ubuntu:bionic

# Released versions are listed here:
# https://dwspectrum.digital-watchdog.com/download/linux
# https://nxvms.com/download/linux
# Latest and beta versions are listed here, substitute the nxwitness strings for dwspectrum:
# http://beta.networkoptix.com/beta-builds/default/
# https://updates.networkoptix.com/digitalwatchdog/30917/linux/dwspectrum-server-4.0.0.30917-linux64.deb
# http://updates.networkoptix.com/digitalwatchdog/30917/windows/dwspectrum-client-4.0.0.30917-win64.exe
ARG DOWNLOAD_URL="https://updates.networkoptix.com/digitalwatchdog/30917/linux/dwspectrum-server-4.0.0.30917-linux64.deb"
ARG DOWNLOAD_VERSION="4.0.0.30917"

# Prevent EULA and confirmation prompts in installers
ENV DEBIAN_FRONTEND=noninteractive \
# NxWitness (networkoptix) or DWSpectrum (digitalwatchdog) or NxMeta (networkoptix-metavms)
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download the DEB installer file, extract it, and make a copy
RUN wget -nv -O ./vms_server_orig.deb ${DOWNLOAD_URL} \
    && dpkg-deb -R ./vms_server_orig.deb ./vms_server_orig \
    && cp -avr ./vms_server_orig ./vms_server_mod

# DEB and LSIO modification logic is based on https://github.com/thehomerepot/nxwitness/blob/master/Dockerfile
# Replace the LSIO abc usernames with the mediaserver names
# https://github.com/linuxserver/docker-baseimage-alpine/blob/master/root/etc/cont-init.d/10-adduser
RUN usermod -l ${COMPANY_NAME} abc \
    && groupmod -n ${COMPANY_NAME} abc \
    && sed -i "s/abc/\${COMPANY_NAME}/g" /etc/cont-init.d/10-adduser

# Remove systemd startup support
# Remove the systemd depency from the dependencies list
# Before: psmisc, systemd (>= 229), cifs-utils
# After: psmisc, cifs-utils
# sed -i 's/systemd.*), //' ./extracted/DEBIAN/control && \
RUN sed -i 's/systemd.*), //' ./vms_server_mod/DEBIAN/control \
# Remove all instructions detailing crash reporting (all text after the "Dirty hack to prevent" line is removed from file)
# sed -i '/# Dirty hack to prevent/q' ./extracted/DEBIAN/postinst && \
    && sed -i '/# Dirty hack to prevent/q' ./vms_server_mod/DEBIAN/postinst \
# Remove the result of systemctl
# Before: systemctl stop $COMPANY_NAME-mediaserver || true
# Before: systemctl stop $COMPANY_NAME-root-tool || true
# After: systemctl stop $COMPANY_NAME-mediaserver 2>/dev/null || true
# After: systemctl stop $COMPANY_NAME-root-tool 2>/dev/null || true
# sed -i "/systemctl.*stop/s/ ||/ 2>\/dev\/null ||/g" ./extracted/DEBIAN/postinst && \
    && sed -i "/systemctl.*stop/s/ ||/ 2>\/dev\/null ||/g" ./vms_server_mod/DEBIAN/postinst \
# Remove the runtime detection logic that uses systemd-detect-virt
# Before: local -r runtime=$(systemd-detect-virt)
# After: local -r runtime=$(echo "none")
# sed -i 's/systemd-detect-virt/echo "none"/' ./extracted/DEBIAN/postinst && \
    && sed -i 's/systemd-detect-virt/echo "none"/' ./vms_server_mod/DEBIAN/postinst \    
# Remove su and chuid from start logic
# Before: su digitalwatchdog -c 'ulimit -c unlimited; ulimit -a'
# Before: --chuid digitalwatchdog:digitalwatchdog \
# After: Blank lines
# sed -i '/^    su/d; /--chuid/d' ./extracted/opt/${COMPANY_NAME}/mediaserver/bin/mediaserver && \
    && sed -i '/^    su/d; /--chuid/d' ./vms_server_mod/opt/${COMPANY_NAME}/mediaserver/bin/mediaserver \
# Remove all the etc/init and etc/systemd folders
    && rm -rf ./vms_server_mod/etc \
# Rebuild the DEB file from the modified directory
    && dpkg-deb -b ./vms_server_mod ./vms_server_mod.deb

# Install the mediaserver
# We can't use --no-install-recommends due to the installer package dependencies being incomplete
RUN apt-get update \
    && apt-get install --yes \
# Install gdb for crash handling (it is used but not included in the deb dependencies)
        gdb gdbserver \
# Install binutils for patching cloud host (from nxwitness docker)
        binutils \
# Install lsb-release used as a part of install scripts inside the deb package (from nxwitness docker)
        lsb-release \
# Install the modified DEB file
    && apt-get install -y ./vms_server_mod.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the original and modified installer files, comment out the cleanup section
# cp -avr ./vms_server_orig ./config/vms_server_orig
# cp -avr ./vms_server_mod ./config/vms_server_mod
# Cleanup
RUN rm -rf ./vms_server_mod \
    && rm -rf ./vms_server_mod.deb \
    && rm -rf ./vms_server_orig \
    && rm -rf ./vms_server_orig.deb

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
# /config is for configuration
# /media is for media recording
# /archive is for media backups
VOLUME /config /media /archive
