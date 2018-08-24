
How To Clear - Mixing content and creating updates
==================================================

## What you'll learn in this chapter

* Initializing a new content stream
* Version numbering
* Format version numbering
* Working with the upstream Clear Linux OS
* Creating and modifying bundles
* Creating the update content
* Creating an update

## The output

The `swupd` software delivery mechanism treats everything as an update.
It does this by querying metadata from an update server and calculating
what it needs to do and which content to use. The format of this
data and metadata is simple, easy to understand, and reproduce, but
`swupd` needs a lot of it.

Since the update content describes every file in the OS, it is a
large database that must be kept synchronized on the client system.
Maintaining these metadata lists is expensive, and the system is
designed to do all the hard work on the server side, so that clients
only need to work on small subsets of the data to perform the needed
operations to update or install components.

`swupd` uses separate files for content and for metadata. Content often
does not change between versions. To save space, the server only stores
one copy of each file in the version that it was last updated. This
content is also compressed on the server, and each piece of content
is identified by a hash value that is unique for both the content of
the data, and the properties of the inode on the file system. In this
way, if a file changes permissions, xattr tags, or ownership, it is
considered a normal update from one content unit to a new content unit.

The metadata is similarly reused between different versions of the OS.
This means that if a bundle doesn't change between two versions, the
`swupd` client will reuse the older version. If a bundle *does* change,
metadata will be updated according to the precise content changes
introduced in the new version. This allows clients to reconstruct
a full new view of the work that needs to be done while maximizing
reuse of the already known metadata.

### Metadata

The metadata that `swupd` uses is stored in Manifests. These manifest
files come in two different levels. Each bundle is maintained in its
own Manifest file, and there is one Manifest-of-Manifests file that
contains metadata on all the Manifests that exist for each bundle.

Here is an example of a Manifest file:

```
MANIFEST       25
version:       21810
previous:      21800
filecount:     1975
timestamp:     1523538780
contentsize:   46217487

D...  6c27df6efcd6fc401ff1bc67c970b83eef115f6473db4fb9d57e5de317eba96e  21530 /boot
D...  6c27df6efcd6fc401ff1bc67c970b83eef115f6473db4fb9d57e5de317eba96e  21530 /dev
D...  6c27df6efcd6fc401ff1bc67c970b83eef115f6473db4fb9d57e5de317eba96e  21530 /etc
L...  3f2e21f5de1fb40955f59667b837b6004254581e64404ce0f0f692bc35a22d76  21530 /usr/bin/b2sum
L...  3f2e21f5de1fb40955f59667b837b6004254581e64404ce0f0f692bc35a22d76  21530 /usr/bin/base32
F...  634ed1be7098435e3a3f28f13740b260e171e9d65891a002998d1e5fc691b471  21530 /usr/bin/chattr
<snip>
```

At the top of the manifest is generic metadata that various CLI
commands use to make tasks such as searching produce better output. The
`format version` sits right at the top and describes the epoch, or
generation of the metadata format. While the format itself is largely
stable, it will be changed any time a breaking change is introduced
to the metadata format. Because this change requires a corresponding
client update, a format boundary ensures that clients update to a
certain version to get the new updater. In this way it can be used
as a milepost marker. The `version` and `previous` metadata come from
the actual Clear Linux OS version.

After the header, there follows a long list of content metadata that
describes the files, directories and links; their content/metadata
hashes; the version last changed; and the various informational flags
for client use.

From left to right, the columns designate the type of content, the
hash of the content, the content version that introduced the content,
and ends with the name of the content as it appears on disk.

The hash itself directly points to a content item on the update
server, and can be found on the HTTP service directly. For instance,
from the above list we can find the `chattr` file by the following URL:

```
https://download.clearlinux.org/update/21530/files/634ed1be7098435e3a3f28f13740b260e171e9d65891a002998d1e5fc691b471.tar
```

Note the version number in the URL isn't `21810` but this content
comes from an earlier update, as listed in the Manifest (`21530`).


### Content

The content that `swupd` delivers is provided to the OS in different
ways to optimize the download and make it as small as possible. For the
most common cases, the server calculates the minimum needed delta
between the content files and creates a binary diff that is very
efficient. If the client needs a clean, and full, copy of the
original file, this is also provided. For the case of someone
installing an entire bundle, the bundle content is provided as a
tarball of the entire content all at once.

The content comes in compressed tar files:

```
$ curl -s -L -O https://download.clearlinux.org/update/21530/files/634ed1be7098435e3a3f28f13740b260e171e9d65891a002998d1e5fc691b471.tar
$ file 634ed1be7098435e3a3f28f13740b260e171e9d65891a002998d1e5fc691b471.tar
634ed1be7098435e3a3f28f13740b260e171e9d65891a002998d1e5fc691b471.tar: XZ compressed data
```

The compression is usually XZ, as this is the most efficient
compression method for most of the content. However, in some cases,
the files will be bzip2 or gzip compressed. The server automatically
finds the best compression algorithm for the content.

The server also creates delta packs and zero packs. These are
optimizations where the server speculatively combines content based on
the assumption that you will need many of them for certain actions. The
client will use them if they are available, but they are entirely
optional. Delta packs contain the binary deltas for changes to files
made from the source update to the target update. For any new files
or files with changes too large for a binary delta, a full file is
included in the delta pack itself. In this way delta packs contain
an update from one arbitrary version to another.

These delta files are created as much as possible to provide clients
with the smallest download possible between two versions. These are
binary deltas made using the `bsdiff` software. They can provide a
significant reduction to the needed download size, but they only work
if the client has the original file already, so they are not always
used. In order for the client to use the delta files, the original
content must also be verified prior to patching.

Similarly, zero packs define an update from one version to another, but
the source version is always zero. Since the zero release contained
no files, the zero pack contains all full files present in the
target version.


## Mixing

The `mixer-tools` suite software generates the update server
content. It does this using the following inputs:

* The Clear Linux OS official software update content
* Local bundle definitions
* Local RPM files

This is exactly how the Clear Linux OS team generates the official
software update content, except that the official Clear Linux OS has
no `upstream` that it bases itself on, and always uses its own bundle
definitions and RPM files to create all the content. The tooling is
exactly the same, however.

We've already seen how the update content looks after it comes out
of the mixer. The goal of this chapter is to get you familiar with
the methods used to create this yourself.


## Initializing the workspace

The mixer tools use a simple workspace to contain all input and output
in a simple folder hierarchy. We call this the mixer workspace. You
can create it simply by making an empty folder:

```
~ $ mkdir ~/mix
~ $ cd ~/mix
~/mix $
```

From here on, we will use the `mixer` CLI tool extensively. This is a
good time to review the CLI and read through the options and general
usage before continuing this training.

```
~/mix $ mixer --help
Mixer is a tool used to compose OS update content and images.

Usage:
  mixer [flags]
  mixer [command]

Available Commands:
  add-rpms    Add RPMs to local dnf repository
  build       Build various pieces of OS content
  bundle      Perform various actions on bundles
  config      Perform config related actions
  help        Help about any command
  init        Initialize the mixer and workspace
  versions    Manage mix and upstream versions

Flags:
      --check        Check all dependencies needed by mixer and quit
  -h, --help         help for mixer
      --offline      Skip caching upstream-bundles; work entirely with local-bundles
      --version      Print version information and quit

Use "mixer [command] --help" for more information about a command.
```

This is also your last chance to double check that `mixer` is
functionally complete and you don't need to install any more Clear
Linux OS bundles.

```
~/mix $ mixer --check
```

We start by initializing mixer. Since we will do more detailed
exercises later in subsequent chapters, we will add a few options to
prevent having to reinitialize the workspace later.

We are also going make updates to the content, both from upstream and
from our own changes. We start the mix with a slightly older version
of Clear Linux OS to demonstrate how this works.

```
~/mix $ mixer init --clear-version 22140 --mix-version 10 --local-rpms
```

* `init` tells mixer to create the needed configuration files and
folders in the workspace
* `--clear-version` tells mixer to start the mix as a mix to this
upstream Clear Linux OS version
* `--mix-version` tells mixer that our own version will start with `10`
which is the default
* `--local-rpms` tells mixer to create folders where we can later add
our own custom RPM files

## builder.conf

```
[Builder]
SERVER_STATE_DIR=/home/clear/mix/update
BUNDLE_DIR=/home/clear/mix/mix-bundles
YUM_CONF=/home/clear/mix/.yum-mix.conf
CERT=/home/clear/mix/Swupd_Root.pem
VERSIONS_PATH=/home/clear/mix

[swupd]
BUNDLE=os-core-update
CONTENTURL=<URL where the content will be hosted>
VERSIONURL=<URL where the version of the mix will be hosted>
FORMAT=1

[Server]
debuginfo_banned=true
debuginfo_lib=/usr/lib/debug/
debuginfo_src=/usr/src/debug/

[Mixer]
LOCAL_BUNDLE_DIR=/home/clear/mix/local-bundles
LOCAL_RPM_DIR=/home/clear/mix/local-rpms
LOCAL_REPO_DIR=/home/clear/mix/local-yum
```

The mixer initialization creates a `builder.conf` file that will store
the basic configuration options for `mixer`. Most of the options are
references to the folder structure in the workspace and some basic
entries that will be needed.

The items of interest in this file for deployment are the `CONTENTURL`
and `VERSIONURL` entries that are needed by systems that will update
against the mix content that we are generating. At a later stage
we'll fill these in.

The `CERT` variable sets the path where mixer stores the certificate
file. The certificate file is used to sign the content so it can be
verified. The software update client uses this certificate to verify
the signature. Mixer automatically generates a certificate, if you
do not provide a path to an existing one, and signs the manifest file.


## Bundles

```
~/mix $ mixer bundle list
bootloader     (upstream bundle)
kernel-native  (upstream bundle)
os-core        (upstream bundle)
os-core-update (upstream bundle)
```

The bundles in the mix are specified in the mix bundle list. Mixer
stores this list as a flat file called mixbundles in the path set
by the `VERSIONS_PATH` variable of the builder.conf file. Mixer
automatically generates the mixbundles list file during initialization.
Mixer reads and writes the bundle list file when you change the
bundles of the mix.

`mixer bundle list` shows a list of every bundle in the mix. Bundles
can include other bundles. Those nested bundles can themselves
include other bundles. When listing bundles with this command, mixer
automatically recurses through the includes to show every single
bundle in the mix.

If you see an unexpected bundle in the list, that bundle is probably
included in another bundle. Use `mixer bundle list --tree` to get a
better view of how a bundle ended up in the mix.

Bundles fall into two categories: upstream and local. Upstream bundles
are those provided by Clear Linux OS. Local bundles are either modified
upstream bundles or new local bundles.

Mixer automatically downloads and caches upstream bundle definition
files. These definition files are stored in the upstream-bundles
directory in the workspace. Do not modify the files in this directory.
This directory is simply a mirror for mixer to use.

The mixer tool automatically caches the bundles for the Clear Linux OS
version configured in the upstreamversion file. Mixer also cleans up
old versions once they are no longer needed. You can see the available
upstream bundles with the following command:

```
~/mix $ mixer bundle list upstream
<snip>
```

Local bundles are bundles that you create, or are edited versions of
upstream bundles.

Local bundle definition files live in the local-bundles directory. The
`LOCAL_BUNDLE_DIR` variable sets the path of this directory in
your builder.conf configuration file. For this example, the path is
`/home/clr/mix/local-bundles`. You can see the available local bundles
with the following command:

```
~/mix $ mixer bundle list local
bootloader     (upstream bundle)
kernel-native  (upstream bundle)
os-core        (upstream bundle)
os-core-update (upstream bundle)
```

Both the local and upstream bundle list commands accept the --tree
flag to show a visual representation of the inclusion relationships
between the bundles in the mix.


## Create the initial mix content

```
~/mix $ mixer build all
<snip>

```

This command creates all the needed content for the version we have
selected and produces a functional `version 10` content stream that
can be used to deploy to targets.

Each time this command is run, the `version` is updated to `+ 10` and
a new update content set is created. If you execute the function a few
times, you'll see the following result in the `www` folder structure:

```
~/mix $ ls update/www/
0  10  20  30  version
```


## Updating

If you desire to update the upstream version of your mix and pull in
upstream changes, you can do this selectively or automatically.

```
~/mix $ mixer versions update --upstream-version 22180
```

Or:

```
~/mix $ mixer versions update --upstream-version latest
```

An important note here is that you can go **back** upstream versions as
long as you're not crossing a `format version` change. If you want to
roll back an upstream change or skip a version, this is all supported.
After doing the `versions update` change, you can simply rebuild the
content again and you are finished.


```
~/mix $ mixer build all
```

## What else to try

* Edit an upstream bundle and change the package list to include or
exclude packages.
* Validate a modified bundle.
* Downgrade your mix to an older upstream version.
