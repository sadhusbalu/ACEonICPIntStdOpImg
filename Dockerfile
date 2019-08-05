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
ENV PATH_TO_MQ_IMAGE=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/


# Install ACE V11 Developer Edition
RUN apt update && apt -y install --no-install-recommends curl rsyslog sudo \
  && curl $PATH_TO_MQ_IMAGE/11.0.0.2-ACE-LINUX64-DEVELOPER.tar.gz \
   | tar xz --exclude ace-11.0.0.2/tools --directory /opt/ibm/ \
  && /opt/ibm/ace-11.0.0.2/ace make registry global accept license silently \
  && apt remove -y curl \
  && rm -rf /var/lib/apt/lists/*


  # Copy in script files


 #DA COPY ./config/*.sh /usr/local/bin/
 COPY ./11.0.0.2/config/*.sh /usr/local/bin/

 RUN chmod +x /usr/local/bin/*.sh

 #RUN /usr/local/bin/setup_var_mqm.sh

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

#DA COPY --chown=aceuser ./binary/$BAR1 /tmp
COPY --chown=aceuser ./11.0.0.2/binary/$BAR1 /tmp

# Unzip the BAR file; need to use bash to make the profile work

USER aceuser

WORKDIR /home/aceuser

RUN bash -c 'mqsibar -w /home/aceuser/ace-server -a /tmp/$BAR1 -c'

# example for testing against MQ on Cloud
#RUN bash -c 'mqsisetdbparms -w /home/aceuser/ace-server -n MQ::mq1 -u mquseroncloud -p d2_kuslE-ppRTU-BbtEisB5vlruhBhj0CrUGDpXNbtxH'

#DA COPY ./config/server.conf.yaml /home/aceuser/ace-server/
COPY ./11.0.0.2/config/server.conf.yaml /home/aceuser/ace-server/

# Switch off the admin REST API for the server run, as we won't be deploying anything after start
#DA RUN sed -i 's/adminRestApiPort/#adminRestApiPort/g' /home/aceuser/ace-server/server.conf.yaml 

# ***** Standard Operating Environment Set Up - FIXED CONFIGURATION END   *****

# Expose ports
EXPOSE 7800 7600

# Set entrypoint to run management script

CMD ["/bin/bash", "-c", "/usr/local/bin/ace_license_check.sh && IntegrationServer -w /home/aceuser/ace-server --console-log"]
