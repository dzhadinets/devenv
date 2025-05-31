#!/bin/bash

set -e

source common-functions

# This script designed to be used a docker ENTRYPOINT "workaround" missing docker
# feature discussed in docker/docker#7198, allow to have executable in the docker
# container manipulating files in the shared volume owned by the USER_ID:GROUP_ID.
#
# Reasonable defaults if no USER_ID/GROUP_ID environment variables are set.
if [ -z ${USER_ID+x} ]; then USER_ID=1000; fi
if [ -z ${GROUP_ID+x} ]; then GROUP_ID=1000; fi

log_dbg "Creating user UID/GID [$USER_ID/$GROUP_ID]"
groupadd -g $GROUP_ID -r $DOCKER_GROUP
useradd -u $USER_ID --create-home -r -g $DOCKER_GROUP $DOCKER_USER

log_dbg "Granting user $DOCKER_USER all sudo privilegies"
adduser $DOCKER_USER sudo >/dev/null
echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "$DOCKER_USER:$DOCKER_USER" | chpasswd

log_dbg "Adding user $DOCKER_USER to group video"
adduser $DOCKER_USER video >/dev/null

if [ -n "$KVM_GID" ] ; then
    log_dbg "Adding user $DOCKER_USER to group kvm"
    groupadd --system -r kvm -o -g $KVM_GID
    adduser $DOCKER_USER kvm >/dev/null
fi

log_dbg "Copying .gitconfig and .ssh/config to new user home" && \
    cp /root/git_config /home/$DOCKER_USER/.gitconfig && \
    chown $DOCKER_USER:$DOCKER_GROUP  /home/$DOCKER_USER/.gitconfig && \
    mkdir -p /home/$DOCKER_USER/.ssh && \
    cp /root/ssh_config /home/$DOCKER_USER/.ssh/config && \
    chown $DOCKER_USER:$DOCKER_GROUP -R /home/$DOCKER_USER/.ssh

# Execute command as user
export HOME=/home/$DOCKER_USER
# Fixes colors in menuconfig
export TERM=xterm-color

for f in /start.d/* ; do
    if [ -x $f ]  && [ ! -d $f ]; then
        log_dbg "Starting $f"
        source $f
    fi
done

# Make dir for .pid file at /var/run/user/${USER_ID}
mkdir --parents --mode=777 /var/run/user/${USER_ID}
log_call service ssh start
log_info $(ifconfig eth0 | grep inet)
set +e
# Default to 'bash' if no arguments are provided
args="$@"
if [ $# -eq 0 ]; then
    log_dbg "Enterring shell"
#    exec sudo -E -s -u $DOCKER_USER
    sudo -u $DOCKER_USER -s -E env "PATH=$PATH"
else
    log_dbg "Performing ...'$args'"
#    exec sudo -E -s -u $DOCKER_USER "$@"
    sudo -s -u $DOCKER_USER -E env "PATH=$PATH" "$@"
fi
exit $?
