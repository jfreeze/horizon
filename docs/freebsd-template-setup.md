# FreeBSD Template Setup

Creating VM templates can save time when deploying new VMs.

This guide covers the initial setup of a FreeBSD host prior to creating a template from the host.

## Server Access Setup
For convenience, we start with defining a host alias in `/etc/hosts` for the existing host.

In this example our hosts are configured on Hetzner Cloud.

Get the public IP of the server from your provider console.
![Server Public IP](images/hetzner-cloud-330.avif)

## Add DNS to `/etc/hosts`
Add the remote server IP to `/etc/hosts`.
We know this server will be `web` so we'll add an alias for `demo-web1`.

```
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost

5.161.249.144   demo-web1
```

## Configure passwordless access to the remote server
Use `ssh-copy-id` to copy your public key to the remote server.

```shell
ssh-copy-id admin@demo-web1                                                     1 ✘  10:23:52 
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/Users/jimfreeze/.ssh/id_rsa.pub"
The authenticity of host 'demo-web1 (5.161.249.144)' can't be established.
ED25519 key fingerprint is SHA256:o6XFCLWgF2HQKNlCip4itEqh5S+AY0sYeKEjlrAtDtQ.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
(admin@demo-web1) Password for admin@:

Number of key(s) added:        1

Now try logging into the machine, with:   "ssh 'admin@demo-web1'"
and check to make sure that only the key(s) you wanted were added.
```

Now verify you can log in without a password.

```shell
❯ ssh admin@demo-web1
FreeBSD 14.1-RELEASE (GENERIC) releng/14.1-n267679-10e31f0946d8

Welcome to FreeBSD!

admin@:~ $ 
```

## Configure the remote server

The `freebsd_setup.sh` script configures new installs of FreeBSD and performs the following tasks:
- Ensures `doas` command (replacement for `sudo`) is installed.
- Configures `doas.conf`
- Verifies SSH `authorized_keys` file is set up and disables password login.
- Runs `freebsd-update` to update the system.

```sh
freebsd_setup.sh admin@demo-web1                                                1 ✘  10:33:44 
[INFO] Ensuring 'doas' is installed on the remote host...
[INFO] Running setup script on remote host admin@demo-web1...
[INFO] Verifying SSH key setup...
[INFO] Backing up existing configuration files...
[INFO] Configuring doas...
[INFO] Configuring .shrc...
[INFO] Configuring sshd...
[INFO] Setting SSH-related permissions...
[INFO] Configuring /boot/loader.conf...
[INFO] Reloading sshd service...
Performing sanity check on sshd configuration.
[INFO] sshd service reloaded successfully.
[INFO] Updating the system...
Looking up update.FreeBSD.org mirrors... 3 mirrors found.
Fetching public key from update1.freebsd.org... done.
Fetching metadata signature for 14.1-RELEASE from update1.freebsd.org... done.
Fetching metadata index... done.
Fetching 2 metadata files... done.
Inspecting system... done.
Preparing to download files... done.
Fetching 115 patches.....10....20....30....40....50....60....70....80....90....100....110.. done.
Applying patches... done.
The following files will be updated as part of updating to
14.1-RELEASE-p6:
/bin/freebsd-version
/boot/kernel/cfiscsi.ko
...
Creating snapshot of existing boot environment... done.
Installing updates...
Restarting sshd after upgrade
Performing sanity check on sshd configuration.
Stopping sshd.
Waiting for PIDS: 84289.
Performing sanity check on sshd configuration.
Starting sshd.
Scanning /usr/share/certs/untrusted for certificates...
Scanning /usr/share/certs/trusted for certificates...
 done.
[INFO] System updated successfully.
[INFO] Initial setup complete.
Please reboot your system and run the following commands after rebooting:
  doas pkg upgrade -y
  doas zfs snapshot zroot/ROOT/default@initial-setup
[INFO] Remote installs complete. Reboot, upgrade and snapshot remaining.
  RUN: ssh admin@demo-web1 'doas shutdown -r now'
```

Follow the instructions to reboot the server and run the upgrade command.

```shell
ssh admin@demo-web1 'doas shutdown -r now'

Shutdown NOW!
shutdown: [pid 83595]
Shutdown NOW!

System shutdown time has arrived
```

Log back in after the server reboots and finish the upgrade.
```shell
ssh admin@demo-web1
```

```shell
admin@:~ $ doas pkg upgrade -y
Updating FreeBSD repository catalogue...
Fetching data.pkg: 100%    7 MiB   7.5MB/s    00:01
Processing entries: 100%
FreeBSD repository update completed. 35521 packages processed.
All repositories are up to date.
Checking for upgrades (1 candidates): 100%
Processing candidates (1 candidates): 100%
Checking integrity... done (0 conflicting)
Your packages are up to date.
```

```shell
doas zfs snapshot zroot/ROOT/default@initial-setup
```

You can verify the snapshot was created with the following command.

```shell
admin@:~ $ zfs list -t snapshot
NAME                                       USED  AVAIL  REFER  MOUNTPOINT
zroot/ROOT/default@2024-11-19-11:35:22-0   394M      -  2.10G  -
zroot/ROOT/default@initial-setup           144K      -  2.12G  -
```

Your server is now set up and ready for Horizon.

## Creating a Template
**We'll use this server as a template to create web hosts, postgres hosts and build hosts.**

If not using Hetzner Cloud, follow the instructions for your provider to create a snapshot of the server.

First, shut down the server.
```shell
ssh admin@demo-web1 "doas shutdown -h now"                         ✔  4h 43m 12s   15:22:12 
Shutdown NOW!
shutdown: [pid 30486]
Shutdown NOW!

System shutdown time has arrived
```

## Create a Snapshot
Go to the Snapshot tab.
![Select Snapshot Tab](images/hetzner-cloud-340.avif)

Create a snapshot of the server.
![Create a Snapshot](images/hetzner-cloud-350.avif)

You now have a snapshot of the server that can be used to create new servers.
![Template Snapshot](images/hetzner-cloud-360.avif)
