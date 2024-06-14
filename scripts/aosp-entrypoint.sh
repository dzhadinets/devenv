#!/bin/bash

set -e

log_dbg "Creating /tmp/ccache and /aosp directory" && \
    mkdir -p /tmp/ccache /aosp && \
    chown $DOCKER_USER:$DOCKER_GROUP /tmp/ccache /aosp
