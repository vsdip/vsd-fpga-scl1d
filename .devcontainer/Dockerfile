FROM ghcr.io/lnis-uofu/openfpga-master:latest

ARG USERNAME=openfpga_user

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       sudo \
       unzip \
       zip vim \
       git \
       curl \
       wget \
       ca-certificates \
       build-essential \
       cmake \
       python3 \
       python3-pip \
       python3-venv \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
