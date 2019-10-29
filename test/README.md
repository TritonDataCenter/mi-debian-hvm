<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2019 Joyent, Inc.
-->

# Testing

There is no automated testing at this time.  The following manual tests likely
point to the start of tests that should be automated.

This testing uses CoaL or a standalone SmartOS instance using the same network
configuration as CoaL.  If your networking config is different, you will need to
modify `import-and-start`.

## Download the image

Save the `.imgmanifest` and `.zfs.gz` file for the image on local storage.

## Import the image and start the instance

If there is a specific ssh public key that you would like to use to access the
instance, copy that public key into the current working directory as
`id_rsa.pub` (regardless of whether it is really an rsa key or not).  If no such
file exists in the current working directory, a new key pair will be generated.

Use [`import-and-start`](import-and-start) to import the image (if not already
imported/installed) and start the instance.  It will automatically connect you
to the console.

```
# ./import-and-start debian-10-20191119.imgmanifest bhyve
```

1. Ensure that the grub menu is displayed and that you can interact with it.

2. Select the appropriate entry to boot the instance.

3. Verify that the banner before the login prompt has Joyent branding and that
it has the appropriate release and date stamp, as shown below.

```
...
   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (Debian 10.2 20191120)
                   `-'   https://docs.joyent.com/images/linux/debian

debian-10-20191119 login:
```

4. Verify that the hostname in the login prompt matches that set in the
   `vmadm create` payload.

### Verify console login

1. Login on the console as root with no password.

```
debian-10-20191119 login: root
Last login: Wed Nov 20 02:03:01 UTC 2019 on ttyS0
Linux debian-10-20191119 4.19.0-6-amd64 #1 SMP Debian 4.19.67-2+deb10u2 (2019-11-11) x86_64
   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (Debian 10.2 20191120)
                   `-'   https://docs.joyent.com/images/linux/debian

root@debian-10-20191119:~#
```

2. Verify that the motd is displayed and the prompt contains the appropriate
hostname.

### Verify ssh configuration

1. Verify that ssh host keys are generated and were created after this instance
   booted.

```
root@debian-10-20191119:~# find /etc/ssh -type f -newer /proc/1
/etc/ssh/ssh_host_ed25519_key.pub
/etc/ssh/ssh_host_rsa_key.pub
/etc/ssh/ssh_host_dsa_key.pub
/etc/ssh/ssh_host_ecdsa_key
/etc/ssh/ssh_host_dsa_key
/etc/ssh/ssh_host_ed25519_key
/etc/ssh/ssh_host_rsa_key
/etc/ssh/ssh_host_ecdsa_key.pub
```

2. Verify that there are no ssh host keys that existed prior to this boot.

```
root@debian-10-20191119:~# find /etc/ssh \! -newer /proc/1
/etc/ssh/ssh_config
/etc/ssh/sshd_config
/etc/ssh/moduli
```

3. Verify sshd is running

```
root@debian-10-20191119:~# systemctl status sshd.service
* ssh.service - OpenBSD Secure Shell server
   Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2019-11-20 01:59:48 UTC; 5min ago
     Docs: man:sshd(8)
           man:sshd_config(5)
  Process: 443 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
 Main PID: 455 (sshd)
    Tasks: 1 (limit: 1123)
   Memory: 5.5M
   CGroup: /system.slice/ssh.service
           `-455 /usr/sbin/sshd -D

Nov 20 01:59:48 debian-10-20191119 systemd[1]: Starting OpenBSD Secure Shell server...
Nov 20 01:59:48 debian-10-20191119 sshd[455]: Server listening on 0.0.0.0 port 22.
Nov 20 01:59:48 debian-10-20191119 sshd[455]: Server listening on :: port 22.
Nov 20 01:59:48 debian-10-20191119 systemd[1]: Started OpenBSD Secure Shell server.
Nov 20 01:59:51 debian-10-20191119 sshd[485]: Accepted publickey for root from 10.88.88.1 port
Nov 20 01:59:51 debian-10-20191119 sshd[485]: pam_unix(sshd:session): session opened for user
```

4. Verify that .ssh/authorized_keys contains only the key that was added via
   `root_authorized_keys`.

### Verify apt configuration

```
root@debian-10-20191119:~# apt update
Hit:1 http://security.debian.org buster/updates InRelease
Hit:2 http://deb.debian.org/debian buster InRelease
Hit:3 http://deb.debian.org/debian buster-updates InRelease
Hit:4 http://deb.debian.org/debian buster-backports InRelease
Reading package lists... Done
Building dependency tree
Reading state information... Done
All packages are up to date.
```

The key here is that it was able to reach repos for the appropriate release and
didn't error out on any unreachable repos, such as one under `/cdrom`.

### Verify disks

```
root@debian-10-20191119:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            469M     0  469M   0% /dev
tmpfs            97M  1.6M   95M   2% /run
/dev/vda1       7.9G  987M  6.5G  14% /
tmpfs           483M     0  483M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           483M     0  483M   0% /sys/fs/cgroup
/dev/vdb        488M  780K  452M   1% /data
tmpfs            97M     0   97M   0% /run/user/0
```

1. The root fs should be about 8 GiB on the first disk (some partition of vda).
2. `/data` should use the whole second disk (vdb).

### Verify mdata utilities

```
root@debian-10-20191119:~# mdata-list
root_authorized_keys
root@debian-10-20191119:~# mdata-put foo bar
root@debian-10-20191119:~# mdata-list
root_authorized_keys
foo
root@debian-10-20191119:~# mdata-get foo
bar
root@debian-10-20191119:~# mdata-delete foo
root@debian-10-20191119:~# mdata-list
root_authorized_keys
```

### reboot

From the console window, reboot.  Do not interact with the cosnsole during
reboot to ensure that the system boots without interaction.

### Verify sudo works

Log in via ssh, then:

```
useradd -s /bin/bash -m foo
echo 'foo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/foo
su - foo
```

1. Verify that this user can do privileged operations

```
foo@debian-10-20191119:~$ sudo tail -1 /etc/shadow
foo:!:18220:0:99999:7:::
```

2. Verify that removal of `/etc/sudoers.d/foo` results in loss of power

```
foo@debian-10-20191119:~$ sudo rm -f /etc/sudoers.d/foo
foo@debian-10-20191119:~$ sudo tail -1 /etc/shadow

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for foo: ^C
```

### Detach from the console

Detach from the console with `^].` (or just `^]` when repeating this test with
kvm).

If you wish, you may destroy the VM with:

```
[root@buglets ~/c6]# vmadm delete bdebac29-7197-e1df-c25d-b387f4ca041b
Successfully deleted VM bdebac29-7197-e1df-c25d-b387f4ca041b
```

However, not doing so at this time may be advantageous because having it running
during the next image import will prevent ZFS from squatting on the memory
needed to start the VM needed for testing another image or brand.
`import-and-start` will automatically delete the instance that was just tested
before creating a new instance.

## basic kvm tests

Set the brand variable, then perform the same tests as were performed with
bhyve, above.

```
# ./import-and-start debian-10-20191119.imgmanifest kvm
```

...
