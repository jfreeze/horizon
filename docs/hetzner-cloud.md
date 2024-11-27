# Hetzner Cloud Setup Guide

A quick guide to creating a FreeBSD host template on [Hetzner Cloud](https://console.hetzner.cloud/projects)

This guide will walk you through setting up a new Hetzner Cloud project, creating a firewall, a network, and adding servers.

After creating a project, our strategy is to create network and firewall collateral first. 
Then we will add servers to the network and create a new server and save it as a template.

That template will be used to create new servers in the future.

## FreeBSD Host Installation on Hetzner Cloud Summary

- [Create a new project](#create-a-new-project)
- [Create a Firewall](#create-a-firewall)
  - [Name SSH and Ping Firewall Rules](#ssh-and-ping-firewall-rules)
  - [SSH and Ping Firewall Rules](#ssh-and-ping-firewall-rules)
  - [Web Server Rules](#web-server-rules)
  - [Phoenix Dev Rule and LAN Rules](#phoenix-dev-rule-and-lan-rules)
  - [Name the Firewall](#name-the-firewall)
- [Create a Network](#create-a-network)

## Create a new project
Browse to [Hetzner Cloud](https://console.hetzner.cloud/projects) and click "New project".

![Create a project](../docs/hetzner-cloud/hetzner-cloud-020.png)

and add your project.

![Create a project](../docs/hetzner-cloud/hetzner-cloud-030.png)

## Project Overview

In the project page, you can configure networks, firewalls, and servers.

![Project page](../docs/hetzner-cloud/hetzner-cloud-050.png)

## Create a Firewall

> **If you are using a Cloudflare Argo Tunnel or other service to expose your app to the internet, the following firewall rules may need to be adapted.**

Click "Create Firewall" to create a new firewall.
![Create a Firewall](../docs/hetzner-cloud/hetzner-cloud-060.png)

### SSH and Ping Firewall Rules
Here we will create `inbound` rules and internal LAN rules.

Hetzner provides rules for `ssh` and `ping` but does not name them.
Feel free to add appropriate names to the rules.

![SSH and Ping Rules](../docs/hetzner-cloud/hetzner-cloud-070.png)

### Web Server Rules

Next, add rules for HTTP and HTTPS.
![Web Server Rules](../docs/hetzner-cloud/hetzner-cloud-080.png)

###  Phoenix Dev Rule and LAN Rules
Open port `4000` for the Phoenix server. 
You can close this port in your production firewall.
Opening this port is helpful when testing deployment because 
this can be accessed when `nginx` is running on port 80 and 443.

Also shown in the image below are the LAN rules that allow servers to talk to each other.
The web hosts will need to access the postgres server on port 5432 and
the postgres backup server will need to access the postgres server for backups.

We open all the ports for the LAN because the servers are in a private network.
![Port 4000 and LAN](../docs/hetzner-cloud/hetzner-cloud-100.png)

### Name the Firewall
![Name the Firewall](../docs/hetzner-cloud/hetzner-cloud-110.png)

## Create a Network
Move next to the network tab and create a new network.
![Create a Network](../docs/hetzner-cloud/hetzner-cloud-120.png)

## Network Zone
Select the network zone that matches where your servers are located.
The default IP range is usually sufficient.
![Network Zone](../docs/hetzner-cloud/hetzner-cloud-130.png)

## Add Servers

Move to the servers tab to add a server to the network.
Click "Add Server" to create a new server.
![Add Servers](../docs/hetzner-cloud/hetzner-cloud-140.png)

### Select an Image
Hetzner does not provide a FreeBSD image, so we will select an existing image and install 
FreeBSD on it using one of the FreeBSD ISO images hosted by Hetzner.

Which image you select is not important because we will be installing FreeBSD from an ISO image.
![Select Server Image](../docs/hetzner-cloud/hetzner-cloud-170.png)

### Select Server Type
Select if you want to use a shared or dedicated CPU.
![Select Server Type](../docs/hetzner-cloud/hetzner-cloud-180.png)

Select the number of CPUs and memory.
![Select Server CPU and Memory](../docs/hetzner-cloud/hetzner-cloud-190.png)

### Select the Firewall
![Select Server Firewall](../docs/hetzner-cloud/hetzner-cloud-160.png)

### Select the Network
![Select Server Network](../docs/hetzner-cloud/hetzner-cloud-200.png)

### Name the Server
![Name the Server](../docs/hetzner-cloud/hetzner-cloud-210.png)

## Server Dashboard Page
Go to the server dashboard page and click "ISO Images" to add the FreeBSD ISO image.
![ISO Images](../docs/hetzner-cloud/hetzner-cloud-230.png)

## Mount FreeBSD ISO
Type `freebsd` in the search box to find the FreeBSD ISO images and mount the most recent image.

![Mount FreeBSD ISO](../docs/hetzner-cloud/hetzner-cloud-240.png)

## Launch Console
Click the console icon to open a console.
![Open a Console](../docs/hetzner-cloud/hetzner-cloud-250.png)

## Open a Console
Once in the console, click "Ctl + Alt + Del" to reboot the server.
**Note that you will need to click into the console and enter keystrokes for the console to recognize and mount the ISO.** (Don't ask me why.)

![Hetzner Console](../docs/hetzner-cloud/hetzner-cloud-260.png)

## FreeBSD Boot Installer
When the ISO is recognized and booted, you will see the FreeBSD boot installer. Press enter to boot the installer.

Follow the steps for [FreeBSD install](freebsd-install.html). 
The notable difference is that you will need to select the `vtnet0` network interface and configure the IPv6 address.
We will configure `vtnet1` for the LAN interface in a later step.
![FreeBSD Boot Installer](../docs/hetzner-cloud/hetzner-cloud-270.png)

The network and IPv6 configuration shown below are additional steps not found in the [FreeBSD install](freebsd-install.html) guide.

## vtnet0 Configuration
Choose `vtnet0` for the public network interface. `vtne1` will be used for the private LAN interface.
![vtnet0 Configuration](../docs/hetzner-cloud/hetzner-cloud-280.png)

## IPv6 Configuration
Configure the IPv6 address for the public network interface.
![IPv6 Configuration](../docs/hetzner-cloud/hetzner-cloud-290.png)

## SLAAC Autoconfiguration for IPv6
![SLAAC Autoconfiguration](../docs/hetzner-cloud/hetzner-cloud-300.png)

Continue with the [FreeBSD install](freebsd-install.html) guide.

## Unmount ISO
After the installation is complete, you will need to reboot the server and then **unmount the ISO image** before it starts up.
![Reboot](../docs/hetzner-cloud/hetzner-cloud-310.png)

## Reboot
Reboot the server and unmount the ISO. Be quick! :-)
![Unmount ISO](../docs/hetzner-cloud/hetzner-cloud-320.png)

## Template Creation

You now have a FreeBSD server that is almost ready to be used as a template for future servers.
Follow the steps in [FreeBSD Template Setup](freebsd-template-setup.html) to complete the template setup.