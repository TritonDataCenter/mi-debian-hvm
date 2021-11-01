<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2020 Joyent, Inc.
-->

# Debian Image Builder

This repo allows one to create custom Debian images for use with Triton.
Other [repositories](https://github.com/joyent?q=mi--hvm) provide equivalent
functionality for other distribution types.

## Requirements

In order to use this repo, you need to have a SmartOS "joyent" brand zone that
is capable of running qemu.  In order to run qemu the instance needs
customization beyond what can be done with Triton APIs.  That is, an operator
needs to customize the instance.  This is typically accomplished by running the
following commands on the appropriate compute node:

```
uuid=XXX	# Change this to the instance uuid

topds=zones/$uuid/data
zfs create -o zoned=on -o mountpoint=/data $topds

zonecfg -z $uuid <<EOF
add dataset
set name=$topds
end
add fs
set dir=/smartdc
set special=/smartdc
set type=lofs
set options=ro
end
add device
set match=kvm
end
EOF
```

## Setup

This relies on the sdc-vmtools repo as a submodule.  You can get the right
version of that with:

```
git submodules update --init
```

If you forget to do that, `create-image` will do it before it tries to use
anything from that submodule.

## Using

To generate a Debian `<version>` image run:

```
# ./create-image -r <version>
```


```
$ ./create-image -h
Usage:
        ./create-image [options] [command ...]
option:
        -h          This message
        -r          Distro release

Commands:
        fetch       Fetch the installation ISO
        iso         Create a kickstart ISO
        image       Generate the image
```

### fetch

Download the distribution's netinst media (.iso) and verify its integrity.
If the required ISO already exists, its integrity is verified.  If it is found
to be corrupt it is fetched again.

This image will be automatically mounted at `/cdrom` during installation.

### iso

Generate an installer ISO image.  This will contain the following:

* `preseed.cfg` - From `debian-<release>/preseed.cfg`.
* `sdc-vmtools` - The current content of the
  [sdc-vmtools](https://github.com/joyent/sdc-vmtools) repo.
* `early-command` - A preinstallation script, from
  `debian-<release>/early-command`
* `late-command` - A postinstallation script, from
  `debian-<release>/late-command`

This image is automatically mounted when the debian installer needs it, but is
not automatically mounted in the chroot (`/target`) while `late-command` is
running.  For that reason, each release's late command needs to mount it at
`/target/cdrom` prior to running `late-command`.


### image

This runs qemu in a way that allows unattended installation using the media
described above.  Once qemu exits, a Triton-compatible
image is generated and stored in the current `bits/<stamp>` directory as
`debian-<release>-<timestamp>.{json,tar.gz}`.

The actual image creation is handled by `sdc-vmutils/bin/create-hybrid-image`.


### upload

This invokes
[bits-upload.sh](https://github.com/joyent/eng/blob/master/tools/bits-upload.sh)
to upload the image to manta and updates.joyent.com.


## Default Settings For Images

Each image has the following characteristics.  See
`debian-<release>/preseed.cfg` for details on which packages are included.

* Disk is 10GB in size (8GB for / and the rest for swap)
* Stock Kernel
* US Keyboard and Language
* Firewall enabled with SSH allowed
* Timezone is set to UTC
* Console is on ttyS0
* Root password is blank: console login is allowed without a password
* Configuration from the SmartOS metadata service is performed using cloud-init.

## Development

The following serves as a guide for adding support for new Debian-like
distributions and versions of existing distributions.

Distribution-specific content is found in a per-distro subdirectory.  For
example, Debian 10 bits are in the `debian-10` directory.  Directory names are
always lower-case.

The following subsections describe the content that may be in a per-distro
directory.

### preseed.cfg file

The [preseed](https://wiki.debian.org/DebianInstaller/Preseed) configuration
file.  Notable parts of this include:

* `cloud-init` is installed, as it is responsible for interacting with the
  host's metadata service to configure networking, run user scripts, etc.  It
  requires `pyserial`, but for "reasons" the cloud-init developers have avoided
  adding pyserial as a dependency.
* `cloud-init` requires configuration in
  `/etc/cloud/cloud.cfg.d/90\_smartos.cfg` to only enable the SmartOS
  datasource, among other things.
* A `preseed/early\_command` (`debian-<release>/early-command`) is used to tail
  the installation log and write it to `/dev/ttyS0`.  This script is run under
  busybox, so avoid the use of anything too fancy.  `qemu` runs in such a way
  that the guest's `ttyS0` appears on `qemu`'s `stdout`, thus allowing the
  installation log to be captured by Jenkins or similar automation that may be
  creating an image.
* A `preseed/late\_command` (`debian-<release>/late-command`) runs at the end of
  the installation to perform the final tweaks on the image.  It runs chroot'd
  in the installed image.

The early and late command scripts need to communicate their successful
execution to `build-image`.  To do this, they need to emit
`JOYENT_STATUS_PRE=ok` (for early command) and `JOYENT_STATUS_POST=ok` (for late
command) to `/dev/ttyS0`.  `build-image` looks for these markers at the
beginning of a line.  The typical way to emit these markers is by adding the
following to the beginning of the script:

```
#! /bin/bash

joyent_status=fail
trap '(echo ""; echo JOYENT_STATUS_POST=$joyent_status; echo "") >>/dev/ttyS0' \
    EXIT

set -ex
```

and end with:

```
set +x
joyent_status=ok
```

`create-image` will verify that all `JOYENT_STATUS_<foo>` tags are set to `ok`,
which only happens if the script in that section runs to completion.

### keys directory

Each GPG key found in the keys directory will be imported into the keyring of
the user running this command.  These keys are used for authenticating the media
that is downloaded by the `fetch` command.

### create-image-overrides.sh

If the distribution requires overrides of any functionality, it should be added
here.  This file is sourced by `create-image` just before processing commands.
In general, the global variables that are all-uppercase are good candidates for
being overridden.

This file does not exist if not needed.
