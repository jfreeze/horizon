# FreeBSD Installation

Installing FreeBSD from an ISO image is a simple process that takes around 3-5 minutes.
If you're used to using containers, you can think of this step as the equivalent of searching for and creating a new container. The upside is you know exactly what is going into your FreeBSD installation.

For most systems. this process only needs to be performed occasionally as FreeBSD systems are updated. This example shows the process for a new installation of FreeBSD 14.1 RELEASE.


## Start the Installer

Select the Boot Installer by hitting enter.
![Start Installer](../docs/freebsd-install/freebsd-install-010.png)

## Select Install
![Select Install](../docs/freebsd-install/freebsd-install-020.png)

## Select Your Keyboard
![Select Your Keyboard](../docs/freebsd-install/freebsd-install-030.png)

## Hostname

You can leave the hostname blank for now as we will set it later during the initial setup.

![Hostname](../docs/freebsd-install/freebsd-install-040.png)

## System Components

We add the ports tree to save time in case it is needed later and we add the source tree for convenience.
![System Components](../docs/freebsd-install/freebsd-install-050.png)

## Disk Setup

We will use the entire disk for the installation. If you have a specific partitioning scheme in mind, you can select the manual option.

![Disk Setup](../docs/freebsd-install/freebsd-install-060.png)

## ZFS Configuration

Use the defaults for ZFS configuration.
![ZFS Configuration](../docs/freebsd-install/freebsd-install-070.png)

## Device Type

This will depend o your hosting setup, but usually we offload any disk redundancy to the hosting provider.

In a typical Horizon setup, the two host types (web and postgres) do not need redundancy as the web hosts are stateless and can be recreated easily and the postgres host is continually backed up (and possibly mirrored).


![Device Type](../docs/freebsd-install/freebsd-install-080.png)

## Drive Selection

Select the device to format.

![Drive Selection](../docs/freebsd-install/freebsd-install-090.png)

## Confirm Formatting
![Confirm Formatting](../docs/freebsd-install/freebsd-install-100.png)

## Checksum Verification
![Checksum Verification](../docs/freebsd-install/freebsd-install-110.png)

## Installation (Archive Extraction)
![Installation (Archive Extraction)](../docs/freebsd-install/freebsd-install-120.png)

## Set Root Password
![Set Root Password](../docs/freebsd-install/freebsd-install-130.png)

## Network Configuration
![Network Configuration](../docs/freebsd-install/freebsd-install-140.png)

## Add IPv4 Interface
![Add IPv4 Interface](../docs/freebsd-install/freebsd-install-150.png)

## Use DHCP
![Use DHCP](../docs/freebsd-install/freebsd-install-160.png)

## IPv6 Configuration

This can skipped if you don't plan to use IPv6.
![IPv6 Configuration](../docs/freebsd-install/freebsd-install-170.png)

## Confirm Network Configuration
![Confirm Network Configuration](../docs/freebsd-install/freebsd-install-180.png)

## Select Timezone
![Select Timezone](../docs/freebsd-install/freebsd-install-200.png)

## Select Country
![Select Country](../docs/freebsd-install/freebsd-install-210.png)

## Select Locality

This is the city closest to your server. If you don't see your city, select the closest one.
![Select Locality](../docs/freebsd-install/freebsd-install-220.png)

## Confirm Timezone
![Confirm Timezone](../docs/freebsd-install/freebsd-install-230.png)]

## Skip Set Date
![Skip Date Setup](../docs/freebsd-install/freebsd-install-240.png)

## Skip Set Time
![Skip Time Setup](../docs/freebsd-install/freebsd-install-250.png)

## System Configuration

It's a good idea to add `ntpd` and `ntpd_sync_on_start` as VM clocks can drift significantly.
Adding `local_unbound` can speed up DNS lookups but is optional.

![System Configuration](../docs/freebsd-install/freebsd-install-260.png)

## System Hardening

Select all the hardening options.

![System Hardening](../docs/freebsd-install/freebsd-install-270.png)

## Add a User
![Add a User](../docs/freebsd-install/freebsd-install-280.png)

## Add User Console

This example adds the `admin` user and sets their group to `wheel`.
Adding the user to the `wheel` group is required to give your user elevated privileges if using the `freebsd_setup.sh` script.

![Add User Console](../docs/freebsd-install/freebsd-install-290.png)

## Exit Guided Install
![Exit Guided Install](../docs/freebsd-install/freebsd-install-320.png)

## Manual Configuration
![Manual Configuration](../docs/freebsd-install/freebsd-install-330.png)

## Add `doas.conf`

At the end of installation but before rebooting, add the `doas` package to your system 
and configure privileges for the `wheel` group.
The simple `doas` configuration will allow you to run commands to setup your hosts.
When you run the `freebsd_setup.sh` script it will enhance `doas.conf`.

![Add doas oops](../docs/freebsd-install/freebsd-install-340.png)

## Oops. Create the directory first.
![Add doas](../docs/freebsd-install/freebsd-install-350.png)

## Add the pkg `doas`
![Add the pkg doas](../docs/freebsd-install/freebsd-install-360.png)

## Exit
![Exit](../docs/freebsd-install/freebsd-install-370.png)

## Reboot
![Reboot](../docs/freebsd-install/freebsd-install-380.png)

Your FreeBSD system is now installed and ready for the next steps.

---