# MPI Node Image
# Base: Ubuntu 22.04 + OpenMPI + SSH

FROM ubuntu:22.04

LABEL maintainer="HPC Project" \
      description="MPI cluster node for simulation"

ENV DEBIAN_FRONTEND=noninteractive
ARG SSH_USER=root
ARG SSH_PASSWORD=root

#  Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        openmpi-bin \
        libopenmpi-dev \
        openssh-server \
        openssh-client \
        build-essential \
        make \
        vim \
        curl \
        bc \
        net-tools \
        iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir -p /var/run/sshd && \
    echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd && \
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config && \
    ssh-keygen -A

# Setup SSH key (dibagi ke semua node)
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa

# SSH client config
RUN printf "Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile /dev/null\n\
    LogLevel ERROR\n" > /root/.ssh/config && \
    chmod 600 /root/.ssh/config

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
