# FreeBSD Installation

Installing FreeBSD from an ISO image is a simple process that takes around 3-5 minutes.
If you're used to using containers, you can think of this step as the equivalent of searching for and creating a new container. The upside is you know exactly what is going into your FreeBSD installation.

For most systems. this process only needs to be performed occasionally as FreeBSD systems are updated. This example shows the process for a new installation of FreeBSD 14.1 RELEASE.


## Start the Installer

Select the Boot Installer by hitting enter.
![Start Installer](images/freebsd-install-010.avif)

## Select Install
![Select Install](images/freebsd-install-020.avif)

## Select Your Keyboard
![Select Your Keyboard](images/freebsd-install-030.avif)

## Hostname

You can leave the hostname blank for now as we will set it later during the initial setup.

![Hostname](images/freebsd-install-040.avif)

## System Components

We add the ports tree to save time in case it is needed later and we add the source tree for convenience.
![System Components](images/freebsd-install-050.avif)

## Disk Setup

We will use the entire disk for the installation. If you have a specific partitioning scheme in mind, you can select the manual option.

![Disk Setup](images/freebsd-install-060.avif)

## ZFS Configuration

Use the defaults for ZFS configuration.
![ZFS Configuration](images/freebsd-install-070.avif)

## Device Type

This will depend o your hosting setup, but usually we offload any disk redundancy to the hosting provider.

In a typical Horizon setup, the two host types (web and postgres) do not need redundancy as the web hosts are stateless and can be recreated easily and the postgres host is continually backed up (and possibly mirrored).


![Device Type](images/freebsd-install-080.avif)

## Drive Selection

Select the device to format.

![Drive Selection](images/freebsd-install-090.avif)

## Confirm Formatting
![Confirm Formatting](images/freebsd-install-100.avif)

## Checksum Verification
![Checksum Verification](images/freebsd-install-110.avif)

## Installation (Archive Extraction)
![Installation (Archive Extraction)](images/freebsd-install-120.avif)

## Set Root Password
![Set Root Password](images/freebsd-install-130.avif)

## Network Configuration
![Network Configuration](images/freebsd-install-140.avif)

## Add IPv4 Interface
![Add IPv4 Interface](images/freebsd-install-150.avif)

## Use DHCP
![Use DHCP](images/freebsd-install-160.avif)

## IPv6 Configuration

This can skipped if you don't plan to use IPv6.
![IPv6 Configuration](images/freebsd-install-170.avif)

## Confirm Network Configuration
![Confirm Network Configuration](images/freebsd-install-180.avif)

## Select Timezone
![Select Timezone](images/freebsd-install-200.avif)

## Select Country
![Select Country](images/freebsd-install-210.avif)

## Select Locality

This is the city closest to your server. If you don't see your city, select the closest one.
![Select Locality](images/freebsd-install-220.avif)

## Confirm Timezone
![Confirm Timezone](images/freebsd-install-230.avif)]

## Skip Set Date
![Skip Date Setup](images/freebsd-install-240.avif)

## Skip Set Time
![Skip Time Setup](images/freebsd-install-250.avif)

## System Configuration

It's a good idea to add `ntpd` and `ntpd_sync_on_start` as VM clocks can drift significantly.
Adding `local_unbound` can speed up DNS lookups but is optional.

![System Configuration](images/freebsd-install-260.avif)

## System Hardening

Select all the hardening options.

![System Hardening](images/freebsd-install-270.avif)

## Add a User
![Add a User](images/freebsd-install-280.avif)

## Add User Console

This example adds the `admin` user and sets their group to `wheel`.
Adding the user to the `wheel` group is required to give your user elevated privileges if using the `freebsd_setup.sh` script.

![Add User Console](images/freebsd-install-290.avif)

## Exit Guided Install
![Exit Guided Install](images/freebsd-install-320.avif)

## Manual Configuration
![Manual Configuration](images/freebsd-install-330.avif)

## Add `doas.conf`

At the end of installation but before rebooting, add the `doas` package to your system 
and configure privileges for the `wheel` group.
The simple `doas` configuration will allow you to run commands to setup your hosts.
When you run the `freebsd_setup.sh` script it will enhance `doas.conf`.

![Add doas oops](images/freebsd-install-340.avif)

## Oops. Create the directory first.
![Add doas](images/freebsd-install-350.avif)

## Add the pkg `doas`
![Add the pkg doas](images/freebsd-install-360.avif)

## Exit
![Exit](images/freebsd-install-370.avif)

## Reboot
![Reboot](images/freebsd-install-380.avif)

Your FreeBSD system is now installed and ready for the next steps.

---