
How To Clear - Deploying updates to a target
============================================

## What you'll learn in this chapter

* Creating an update content server
* Creating images
* Deploying an initial image to a target
* Starting a Clear Linux Virtual Machine
* Switching the Clear Linux machine to use the custom mix update content


## Conveying the content to a target

For the purpose of this training, we decided to choose a setup that can 
be reproduced easily using a stock Clear Linux OS. The simplest setup 
is to use a simple VM that will be updating against our locally 
produced mix content.

For this we will need to setup a HTTP service that the client can 
connect to. We will be using `nginx` for this since it comes with Clear 
Linux OS in a bundle. This will need some minor configuration. We won't 
cover more complex `nginx` setup issues and avoid topics like `certbot` 
which will be different for most setups.


## nginx

```
~/mix $ sudo swupd bundle-add web-server-basic
```

This installs the `nginx` service onto your device. It doesn't start by 
default and we'll need to configure it.

```
~/mix $ sudo mkdir -p /etc/nginx/conf.d
~/mix $ sudo cp /usr/share/nginx/conf/nginx.conf.example /etc/nginx/nginx.conf
```

The default `nginx` configuration works just fine as a base nginx 
config file. We'll create a specific update server config separately. 
To do that, we create a small config file for nginx that will make it 
point to our update content directly.

```
~/mix $ sudoedit /etc/nginx/conf.d/mixer.conf
```

Insert the following content into the `mixer.conf` file:

```
server {
	server_name localhost;
	location / {
		root /home/clear/mix/update/www;
		autoindex on;
	}
}
```

Make sure to insert the correct username in case your username isn't 
`clear`.

Once this file is in place we can start the http server and you should 
be able to view the content by visiting `http://localhost`:

```
~/mix $ systemctl restart nginx
```

## Conveying the URL to mixer

Once this is functional, we can tell `mixer` to point to this content 
by its URL. To do this, we need to edit `builder.conf` and change the 
following options to properly point the system to the mix we're going 
to be making.

Because of an issue with Qemu and networking, we'll need to point the 
OS inside the virtual machine at the external IP address of the most 
where `nginx` is running. We can find out the IP address with the 
following command:

```
~/mix $ networkctl status
```

There are likely 2 or 3 entries listed under `Address` in the output of 
this command, and all should be valid, but it is usually best to pick 
the top one listed for use in the `builder.conf`:

```
CONTENTURL=http://10.1.2.138/
VERSIONURL=http://10.1.2.138/
```

Now that that is in place, we can proceed to the next step, which is to 
create an image for a VM.


## VM kernel

We need to create an image for a QEMU virtual machine. We can use the 
standard bundle list that mixer uses by default, but this includes the 
`native` kernel. This is not very efficient, as the QEMU virtual 
machine only includes a very small set of hardware, and we don't need 
all the hundreds of drivers that the `native` kernel includes. For this 
reason, we want to modify our default bundle set already so we have a 
smaller amount of content to process, and we'll get a faster boot time 
out of it, simply because the kernel image will be a lot smaller and 
faster to load.

To do this, we are going to include the `kernel-kvm` bundle in our mix, 
and we'll use the upstream content for now:

```
~/mix $ mixer bundle add kernel-kvm
```

We'll need to generate an update so that the new kernel images are 
available in our content stream and the image will be able to include 
it:

```
~/mix $ sudo mixer build all
```

You should verify that the `www` content contains a new version, and 
that a `Manifest.kernel-kvm` now exists in the latest version of the 
update content.


## Create the image

We'll need to generate an `ister` config file that describes what kind 
of image we're creating and what needs to go into the image. For the 
purpose of this training we're going to make a `live` image that we can 
boot straight into without the need for an installation step. First, we 
create the file `release-image-config.json` with the following content 
in the mix folder:

```
{
    "DestinationType" : "virtual",
    "PartitionLayout" : [ { "disk" : "release.img", "partition" : 1, "size" : "32M", "type" : "EFI" },
                          { "disk" : "release.img", "partition" : 2, "size" : "16M", "type" : "swap" },
                          { "disk" : "release.img", "partition" : 3, "size" : "10G", "type" : "linux" } ],
    "FilesystemTypes" : [ { "disk" : "release.img", "partition" : 1, "type" : "vfat" },
                          { "disk" : "release.img", "partition" : 2, "type" : "swap" },
                          { "disk" : "release.img", "partition" : 3, "type" : "ext4" } ],
    "PartitionMountPoints" : [ { "disk" : "release.img", "partition" : 1, "mount" : "/boot" },
			       { "disk" : "release.img", "partition" : 3, "mount" : "/" } ],
    "Version": "latest",
    "Bundles": ["kernel-kvm", "os-core", "os-core-update"]
}
```

After this file is in place, `mixer` can properly start `ister` for us 
with the `build image` subcommand.

```
~/mix $ sudo mixer build image
```

This outputs a file called `release.img` which is directly bootable in 
Qemu. We use the standard `start_qemu.sh` script to invoke Qemu to then 
invoke the image and redirect the VM output to our local console. For 
this we also need the `OVMF.fd` file. These can be found in the `files` 
folder inside the training repository.

```
~/mix $ sudo ./start_qemu.sh release.img
```

You'll need to log in as root and immediately provide a new root 
password, as you may be familiar with already - Clear Linux OS does not 
ship with a default root password.

After logging in as root, you'll find that `swupd update` should 
display that there are no current updates available, and it should list 
your latest mix content version as the last available update.

If we create a new update on the outside of the VM quickly with:

```
~/mix $ sudo mixer build all
```

And then run `swupd update` inside the VM, we should see the update 
apply.


## Exercises

* List your own mix bundles on your target system.
* Verify your install.
* Downgrade your target system with `swupd`, and then update it again.
* Create an installer image using the installer configuration file at 
[https://download.clearlinux.org/current/config/image/installer-config.json]. You'll also need the referenced python script.
