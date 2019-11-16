FROM lsiobase/ubuntu:bionic

LABEL name="DWSpectrum-LSIO" \
    version="4.0.0.29990" \
    description="DW Spectrum IPVMS Docker based on LinuxServer" \
    maintainer="Pieter Viljoen <ptr727@users.noreply.github.com>"

# Latest versions are listed here:
# https://dwspectrum.digital-watchdog.com/download/linux
# https://nxvms.com/download/linux
# Using DWSpectrum server v4.0.0.29990
ENV downloadurl="https://digital-watchdog.com/forcedown?file_path=_gendownloads/70b537f9-c2ae-4d5b-9ee1-519003049542/&file_name=dwspectrum-server-4.0.0.29990-linux64.deb&file=OGR6MElZbXpxWEs2TXU1cHpKYXR1U1R0THN1THpGdzlyb3QveE95dHhCTT0=" \
# The NxWitness and DwSpectrum apps are nearly identical, but the installer uses different folder names and different user accounts, complicating scripting
    COMPANY_NAME="digitalwatchdog" \
# Note, I have not tested this docker setup with NxWitness
    #COMPANY_NAME="networkoptix" \
# Prevent EULA and confirmation prompts in installers
    DEBIAN_FRONTEND=noninteractive

# DEB file modification logic based on https://github.com/thehomerepot/nxwitness/blob/master/Dockerfile

RUN apt-get update \
# Install wget so we can download the installer    
    && apt-get install -y wget \
# Download the DEB installer file    
    && wget -nv -O ./vms_server.deb ${downloadurl} \
# Extract the DEB file so we can modify it before installing
    && dpkg-deb -R ./vms_server.deb ./vms_server \
# Remove the systemd depency from the dependencies list
# Before: psmisc, systemd (>= 229), cifs-utils
# After: psmisc, cifs-utils
    && sed -i 's/systemd.*), //' ./vms_server/DEBIAN/control \
# Remove all instructions detailing crash reporting (all text after the "Dirty hack to prevent" line is removed from file)
    && sed -i '/# Dirty hack to prevent/q' ./vms_server/DEBIAN/postinst \
# Remove the runtime detection logic that uses systemd-detect-virt
# Before: local -r runtime=$(systemd-detect-virt)
# After: local -r runtime=$(echo "none")
    && sed -i 's/systemd-detect-virt/echo "none"/' ./vms_server/DEBIAN/postinst \    
# Remove the result of systemctl
# Before: systemctl stop $COMPANY_NAME-mediaserver || true
# Before: systemctl stop $COMPANY_NAME-root-tool || true
# After: systemctl stop $COMPANY_NAME-mediaserver 2>/dev/null || true
# After: systemctl stop $COMPANY_NAME-root-tool 2>/dev/null || true
    && sed -i "/systemctl.*stop/s/ ||/ 2>\/dev\/null ||/g" ./vms_server/DEBIAN/postinst \
# Remove su and chuid from start logic
# Before: su digitalwatchdog -c 'ulimit -c unlimited; ulimit -a'
# Before: --chuid digitalwatchdog:digitalwatchdog \
# After: Blank lines
    && sed -i '/^    su/d; /--chuid/d' ./vms_server/opt/${COMPANY_NAME}/mediaserver/bin/mediaserver \
# Remove all the etc/init and etc/systemd folders
    && rm -rf ./vms_server/etc \
# Rebuild the DEB file from the modified directory
    && dpkg-deb -b ./vms_server ./vms_server_mod.deb \
# Replace the LSIO abc usernames with the server app names
    && usermod -l ${COMPANY_NAME} abc \
    && groupmod -n ${COMPANY_NAME} abc \
    && sed -i "s/abc/\${COMPANY_NAME}/g" /etc/cont-init.d/10-adduser \
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
COPY root/etc /etc

# Expose port 7001
EXPOSE 7001

# Create data volumes
VOLUME /config /archive
