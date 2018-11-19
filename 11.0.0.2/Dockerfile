# © Copyright IBM Corporation 2018.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v2.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v20.html

FROM ubuntu:16.04

LABEL "maintainer"="Dan Robinson <dan.robinson@uk.ibm.com>" \
      "product.id"="447aefb5fd1342d5b893f3934dfded73" \
      "product.name"="IBM App Connect Enterprise" \
      "product.version"="11.0.0.2"

WORKDIR /opt/ibm

# ***** Set your path to installation images
#ENV PATH_TO_MQ_IMAGE=http://9.192.234.35/~peterajessup/files
ENV PATH_TO_MQ_IMAGE=http://172.23.50.125/iib10/


# Install ACE V11 Developer Edition
RUN apt update && apt -y install --no-install-recommends curl rsyslog sudo \
  && curl $PATH_TO_MQ_IMAGE/11.0.0.2-ACE-LINUX64-DEVELOPER.tar.gz \
   | tar xz --exclude ace-11.0.0.2/tools --directory /opt/ibm/ \
  && /opt/ibm/ace-11.0.0.2/ace make registry global accept license silently \
  && apt remove -y curl \
  && rm -rf /var/lib/apt/lists/*

# Install the MQ Client

ARG MQ_URL=$PATH_TO_MQ_IMAGE/mqadv_dev910_ubuntu_x86-64.tar.gz
ARG MQ_PACKAGES="ibmmq-runtime ibmmq-client ibmmq-java ibmmq-jre"



RUN export DEBIAN_FRONTEND=noninteractive \
  # Install additional packages required by MQ, this install process and the runtime scripts
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    bash \
    bc \
    ca-certificates \
    coreutils \
    curl \
    debianutils \
    file \
    findutils \
    gawk \
    grep \
    libc-bin \
    lsb-release \
    mount \
    passwd \
    iputils-ping \
    procps \
    sed \
    tar \
    util-linux \
    apt-utils \
  # Download and extract the MQ installation files
  && export DIR_EXTRACT=/tmp/mq \
  && mkdir -p ${DIR_EXTRACT} \
  && cd ${DIR_EXTRACT} \
  && curl -LO $MQ_URL \
  && tar -zxvf ./*.tar.gz \
  # Recommended: Remove packages only needed by this script
  && apt-get purge -y \
    ca-certificates \
    curl \
  # Recommended: Remove any orphaned packages
  && apt-get autoremove -y --purge \
  # Recommended: Create the mqm user ID with a fixed UID and group, so that the file permissions work between different images
  && groupadd --system --gid 999 mqm \
  && useradd --system --uid 999 --gid mqm mqm \
  && usermod -G mqm root \
  # Find directory containing .deb files
  && export DIR_DEB=$(find ${DIR_EXTRACT} -name "*.deb" -printf "%h\n" | sort -u | head -1) \
  # Find location of mqlicense.sh
  && export MQLICENSE=$(find ${DIR_EXTRACT} -name "mqlicense.sh") \
  # Accept the MQ license
  && ${MQLICENSE} -text_only -accept \
  && echo "deb [trusted=yes] file:${DIR_DEB} ./" > /etc/apt/sources.list.d/IBM_MQ.list \
  # Install MQ using the DEB packages
  && apt-get update \
  && apt-get install -y $MQ_PACKAGES \
  # Remove 32-bit libraries from 64-bit container
  && find /opt/mqm /var/mqm -type f -exec file {} \; \
    | awk -F: '/ELF 32-bit/{print $1}' | xargs --no-run-if-empty rm -f \
  # Remove tar.gz files unpacked by RPM postinst scripts
  && find /opt/mqm -name '*.tar.gz' -delete \
  # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
  && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
  # Clean up all the downloaded files
  && rm -f /etc/apt/sources.list.d/IBM_MQ.list \
  && rm -rf ${DIR_EXTRACT} \
  # Apply any bug fixes not included in base Ubuntu or MQ image.
  # Don't upgrade everything based on Docker best practices https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run
  && apt-get install -y libapparmor1 libsystemd0 systemd systemd-sysv libudev1 --only-upgrade \
  # End of bug fixes
  && rm -rf /var/lib/apt/lists/* \
  # Optional: Update the command prompt with the MQ version
  && echo "mq:$(dspmqver -b -f 2)" > /etc/debian_chroot \
  && rm -rf /var/mqm \
  && mkdir -p /etc/mqm \
  && mkdir -p /etc/mqm


  # Copy in script files


 COPY ./config/*.sh /usr/local/bin/

 RUN chmod +x /usr/local/bin/*.sh

 RUN /usr/local/bin/setup_var_mqm.sh

# Configure ace system
RUN echo "ACE_11:" > /etc/debian_chroot \
  && touch /var/log/syslog \
  && chown syslog:adm /var/log/syslog \
# Increase security
  && sed -i 's/sha512/sha512 minlen=8/'  /etc/pam.d/common-password \
  && sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t1/'  /etc/login.defs \
  && sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs





# Create a user to run as, create the ace workdir, and chmod script files
RUN useradd --create-home --home-dir /home/aceuser -G mqbrkrs,sudo,mqm aceuser \
  && sed -e 's/^%sudo	.*/%sudo	ALL=NOPASSWD:ALL/g' -i /etc/sudoers \
  && su - aceuser -c '. /opt/ibm/ace-11.0.0.2/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server' \
  && chmod 755 /usr/local/bin/*

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/usr/local/bin/ace_env.sh

# ***** Standard Operating Environment Set Up - FIXED CONFIGURATION START *****
ENV BAR1=SoE.bar

COPY --chown=aceuser ./binary/$BAR1 /tmp

# Unzip the BAR file; need to use bash to make the profile work

USER aceuser

WORKDIR /home/aceuser

RUN bash -c 'mqsibar -w /home/aceuser/ace-server -a /tmp/$BAR1 -c'

# example for testing against MQ on Cloud
#RUN bash -c 'mqsisetdbparms -w /home/aceuser/ace-server -n MQ::mq1 -u mquseroncloud -p d2_kuslE-ppRTU-BbtEisB5vlruhBhj0CrUGDpXNbtxH'

COPY ./config/server.conf.yaml /home/aceuser/ace-server/

# Switch off the admin REST API for the server run, as we won't be deploying anything after start
RUN sed -i 's/adminRestApiPort/#adminRestApiPort/g' /home/aceuser/ace-server/server.conf.yaml 

# ***** Standard Operating Environment Set Up - FIXED CONFIGURATION END   *****

# Expose ports
EXPOSE 7800 7600

# Set entrypoint to run management script

CMD ["/bin/bash", "-c", "/usr/local/bin/ace_license_check.sh && IntegrationServer -w /home/aceuser/ace-server --console-log"]
