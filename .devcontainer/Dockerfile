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
       xvfb \
       xfce4 \
       xfce4-session \
       xfce4-panel \
       xfdesktop4 \
       xfwm4 \
       xfce4-terminal \
       thunar \
       dbus-x11 \
       x11vnc \
       novnc \
       websockify \
       supervisor \
       librsvg2-bin \
       ristretto \
       klayout \
    && DEBIAN_FRONTEND=noninteractive apt-get purge -y xfce4-screensaver light-locker \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && rm -rf /var/lib/apt/lists/*

COPY .devcontainer/supervisord.conf /etc/supervisor/conf.d/vnc.conf

EXPOSE 6080

# Codespaces uses remoteUser=openfpga_user for terminals. Supervisor starts
# as root so it can run the desktop processes as openfpga_user.
CMD ["/usr/bin/supervisord", "-n"]
