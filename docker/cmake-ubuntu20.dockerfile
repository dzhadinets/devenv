#
# Docker image to build CMake based project
#
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# upggade to the latest secure updates
RUN apt-get -q update && \
    apt-get install -y apt-utils && \
    apt-get -q -y upgrade

# Locale
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# install essential packages
RUN apt-get install -y \
    sudo \
    curl \
    wget \
    vim mg \
    screen \
    git-core \
    unzip

# install additional DEV tools (build-essential: gcc, g++, libc-dev, dpkg-dev, make)
RUN apt-get install -y \
    build-essential \
    pkg-config

# install cmake essential packages
RUN apt-get install -y \
    cmake \
    cmake-curses-gui \
    strace \
    valgrind \
    libgtest-dev \
    libgmock-dev \
    gcovr \
    gnupg \
    dbus \
    dbus-user-session \
    systemd \
    nodejs \
    clangd

# install cmake essential packages
RUN apt-get install -y \
    clangd \
    cppcheck

# Minimize container size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY docker/git_config /root/git_config
COPY docker/ssh_config /root/ssh_config

# Set environment for DBUS operation
RUN mkdir -p /var/run/dbus/

RUN mkdir -p /start.d

ENV DOCKER_USER builder
ENV DOCKER_GROUP builder

COPY scripts/cmake-entrypoint.sh /start.d/001-cmake-builder.sh
RUN chmod 755 /start.d/001-cmake-builder.sh

COPY scripts/common-functions /usr/bin/common-functions

COPY scripts/common-entrypoint.sh /root/docker-entrypoint.sh
RUN chmod 755 /root/docker-entrypoint.sh
ENTRYPOINT ["/root/docker-entrypoint.sh"]
