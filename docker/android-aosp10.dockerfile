#
# Minimum Docker image to build Android AOSP
#
FROM ubuntu:20.04

# /bin/sh points to Dash by default, reconfigure to use bash until Android
# build becomes POSIX compliant
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

RUN apt-get update && \
    apt-get install -y software-properties-common

RUN add-apt-repository ppa:openjdk-r/ppa

# Keep the dependency list as short as reasonable

RUN apt-get update && \
    apt-get install -y bc bison bsdmainutils build-essential curl vim symlinks \
    flex g++-multilib gcc-multilib git gnupg gperf lib32ncurses-dev rsync \
    lib32z1-dev libncurses-dev libssl-dev \
    libsdl1.2-dev libxml2-utils lzop sudo \
    openjdk-8-jdk \
    pngcrush schedtool xsltproc zip zlib1g-dev graphviz openssh-server mkisofs
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# to resolve ncurses5 dependency
RUN ln -s /usr/lib/x86_64-linux-gnu/libncursesw.so.6 /usr/lib/libtinfo.so.5
RUN ln -s /usr/lib/x86_64-linux-gnu/libncursesw.so.6 /usr/lib/libncurses.so.5

ADD https://commondatastorage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/*
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 2

# All builds will be done by user aosp
COPY docker/git_config /root/git_config
COPY docker/no_strict_ssh_config /root/ssh_config

ENV DOCKER_USER aosp
ENV DOCKER_GROUP aosp

RUN mkdir -p /start.d

# Android emulator setup
# add directory and setup android sdk and other tools for emulator
RUN mkdir emulator \
    && wget http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz -P /emulator/  --progress=bar:force:noscroll \
    && tar -xf /emulator/android-sdk_r24.4.1-linux.tgz  --directory /emulator/ > /dev/null\
    && rm  /emulator/android-sdk_r24.4.1-linux.tgz \
    && echo y | /emulator/android-sdk-linux/tools/android update sdk -u -a -t 52 > /dev/null \
    && echo y | /emulator/android-sdk-linux/tools/android update sdk -u -a -t 2 > /dev/null\
    && echo y | /emulator/android-sdk-linux/tools/android update sdk -u -a -t 1 > /dev/null\
    && echo y | /emulator/android-sdk-linux/tools/bin/sdkmanager "cmdline-tools;8.0" > /dev/null\
    && /emulator/android-sdk-linux/cmdline-tools/8.0/bin/sdkmanager --install "system-images;android-29;google_apis;x86_64"


COPY scripts/aosp-entrypoint.sh /start.d/001-aosp-builder.sh
RUN chmod 755 /start.d/001-aosp-builder.sh

COPY scripts/common-functions /usr/bin/common-functions

COPY scripts/common-entrypoint.sh /root/docker-entrypoint.sh
RUN chmod 755 /root/docker-entrypoint.sh
ENTRYPOINT ["/root/docker-entrypoint.sh"]
