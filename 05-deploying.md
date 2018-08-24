
How To Clear - Deploying updates to a target
============================================

## What you'll learn in this chapter

* Creating an update content server
* Creating images
* Deploying an initial image to a target
* Starting a Clear Linux OS based Virtual Machine (VM)
* Switching the Clear Linux machine to use the custom mix update content


## Conveying the content to a target

For the purpose of this training, we chose a setup that can be
reproduced easily using a stock Clear Linux OS. The simplest setup is
to use a simple VM that will be updating against our locally produced
mix content.

We will set up a HTTP service for the client using `nginx` because
it comes with Clear Linux OS in a bundle. `nginx` needs some minor
configuration but we won't cover more complex `nginx` setup issues
here. This training does not cover topics like `certbot` which will
be different for most setups.


## nginx

```
~/mix $ sudo swupd bundle-add web-server-basic
```

This installs the `nginx` service onto your device. It doesn't start
by default and we need to configure it.

```
~/mix $ sudo mkdir -p /etc/nginx/conf.d
~/mix $ sudo cp /usr/share/nginx/conf/nginx.conf.example /etc/nginx/nginx.conf
```

The default `nginx` configuration works just fine as a base nginx
config file. We'll create a specific update server config separately.
To do that, we create a small config file for nginx that will make
it point to our update content directly.

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

Once this file is in place, we start the http server and you can view
the content by visiting `http://localhost`:

```
~/mix $ sudo systemctl restart nginx
```

## Conveying the URL to mixer

Once this is functional, we tell `mixer` to point to this content by
its URL. To do this, we edit `builder.conf` and change the following
options to properly point the system to the mix we are making.

Because of an issue with QEMU\* and networking, we point the OS
inside the virtual machine at the external IP address of the host
where `nginx` is running. We can find out the IP address with the
following command:

```
~/mix $ networkctl status
```

There are likely 2 or 3 entries listed under `Address` in the output
of this command. All entries should be valid, but we recommend you
pick the top one listed for use in the `builder.conf`:

```
CONTENTURL=http://10.276.302.138/
VERSIONURL=http://10.276.302.138/
```

Now that that is in place, we can proceed to the next step, which is
to create an image for a VM.


## VM kernel

We need to create an image for a QEMU virtual machine. We can use the
standard bundle list that mixer uses by default, but this includes
the `native` kernel. This is not very efficient, as the QEMU virtual
machine only includes a very small set of hardware, and we don't need
all the hundreds of drivers that the `native` kernel includes. For
this reason, we want to modify our default bundle set already so we
have a smaller amount of content to process. We'll get a faster boot
time out of it, simply because the kernel image will be smaller and
faster to load.

To do this, we include the `kernel-kvm` bundle in our mix, and we
use the upstream content for now:

```
~/mix $ mixer bundle add kernel-kvm
```

We need to generate an update so that the new kernel images are
available in our content stream and the image will be able to
include it:

```
~/mix $ mixer build all
```

You should verify that the `www` content contains a new version,
and that a `Manifest.kernel-kvm` now exists in the latest version of
the update content.


## Create the image

We need to generate an `ister` config file that describes what kind
of image we're creating and what needs to go into the image. For the
purpose of this training, we will make a `live` image that we can
boot straight into without the need for an installation step. First,
we create the file `release-image-config.json` with the following
content in the mix folder:

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

After this file is in place, `mixer` can properly start `ister`
for us with the `build image` subcommand.

```
~/mix $ sudo mixer build image --native
```

Note: If you have made any changes to `builder.conf` or the content
of your mix, you need to run `sudo mixer build all` before creating
a new image, otherwise your image may be built with old content and
not include the needed URL changes for `swupd` to work properly inside
the image.

This outputs a file called `release.img` which is directly bootable
in QEMU. We use the standard `start_qemu.sh` script to invoke QEMU
to then invoke the image and redirect the VM output to our local
console. For this we also need the `OVMF.fd` file. These can be found
in the `files` folder inside the training repository.

```
~/mix $ sudo ./start_qemu.sh release.img
```

You need to log in as root and immediately provide a new root password,
because Clear Linux OS does not ship with a default root password,
as you may already know.

After logging in as root, `swupd update` will display that there
are no current updates available, and it will list your latest mix
content version as the last available update.

If we create a new update on the outside of the VM quickly with:

```
~/mix $ mixer build all
```

Then run `swupd update` inside the VM, we will see the update apply.


## Exercises

* List your own mix bundles on your target system.
* Verify your install.
* Downgrade your target system with `swupd`, and then update it again.
* Create an installer image using the installer configuration file at
[https://download.clearlinux.org/current/config/image/installer-config.json]. You will need the referenced Python* script.
