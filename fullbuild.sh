#!/usr/bin/env bash
#
# Copyright (c) 2015 Joyent Inc., All rights reserved.
#

set -euo pipefail
IFS=$'\n\t'


if [[ ! -d sdc-vmtools ]] ; then
  echo "sdc-vmtools  not found!"
  exit 1
fi

includes=config/includes.chroot
sdcvmtools=sdc-vmtools/src/linux

echo "Syncing etc, lib, and usr directories to ${includes}..."
# Using rsync to ensure deleted files from sdc-vmtools repo are removed
rsync -aq --delete --exclude=install-tools.sh ./${sdcvmtools}/ ${includes}/

echo "==> Starting build!"

echo "==> Cleaning up..."
lb clean

echo "==> Configuring..."
lb config

echo "==> Building..."
lb build

exit 0
