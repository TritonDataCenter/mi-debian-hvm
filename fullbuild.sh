#!/usr/bin/env bash
#
# Copyright (c) 2015 Joyent Inc., All rights reserved.
#

set -euo pipefail
IFS=$'\n\t'

INCLUDES=config/includes.chroot
GUESTTOOLS=sdc-vmtools/src/linux

echo "==> Copying Guest tools to ${INCLUDES}"
echo "====> Initiallizing and fetching submodule sdc-vmtools"
git submodule init
git submodule update

echo "Syncing etc, lib, and usr directories to ${INCLUDES}..."
# Using rsync to ensure deleted files from sdc-vmtools repo are removed
rsync -aq --delete --exclude=install-tools.sh ./${GUESTTOOLS}/ ${INCLUDES}/

echo "==> Starting build!"

echo "==> Cleaning up..."
lb clean

echo "==> Configuring..."
lb config

echo "==> Building..."
lb build

exit 0
