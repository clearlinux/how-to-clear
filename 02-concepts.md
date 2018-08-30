
How To Clear - Clear Linux distribution concepts
================================================

## What this document explains

In the training, we will use the Clear Linux OS Team vocabulary to
describe processes, concepts, and data. Since this vocabulary has
grown over time in the team, it may not be the most logical naming for
people who start to learn about how Clear Linux OS is created. This
chapter attempts to explain the idea behind the terminology.


## Goal

The end goal of this training is that the student understands how
to create and deliver a custom version of Clear Linux OS using the
tooling explained in this training. The full picture of how that
looks is graphically summarized in the following graph:.

![Clear Mixer Architecture](/files/clear-mixer-architecture.png)

The graph shows how content from the official Clear Linux OS and any
custom content can be mixed to create both images, and an update
content stream.

The update content stream will need to be made available as HTTP or
HTTPS data on a network connection. It is the equivalent of a package
repository.

The initial setup of machines needs to happen with bootable images
that can either live boot, or install the base OS.


## Updates

The concept of updates is central to the design of the Clear Linux
OS method of delivering and maintaining the OS. In essence, every
modification to the OS is considered an update. This includes
installation, updates themselves, and the addition of optional
components. In principle, even rolling back to an older version is
an update.

The content originates from an "update server". This is implemented by
a https enabled webserver where the files are served as static content.
The Clear Linux OS periodically queries the data on the update server
and determines whether updates are available, and in case the OS wants
to install optional components, or even when a new installation is
performed. In all those cases, the update content files provides all
the data and metadata to perform all the needed actions.


## Bundles

In Clear Linux OS, the choice was made to do away with packages as
the smallest functional component size. One of the main reasons is
that packages in a disproportionate sense are unusable to users by
themselves, and require a large amount of packages to be installed
before the functionality they offer can be used.

For example, the xorg-server package does not provide a function X
server without the presence of about 30+ additional components. On top
of that, in order to create these 30 or so components, an additional
200 or so packages are needed for various aspects of the creation of
the X server binary.

In Clear Linux OS, bundles are the concept of the smallest usable
collection of packages that provide a functional component, and
traditional packages are not visible to the user. In some cases, it
could mean that a bundle effectively contains a single package (e.g.
the "curl" bundle), but in most cases a bundle contains several or
even many packages.


## Manifests

The Clear Linux OS software update content consists of data and
metadata.  The data is the files that end up in the OS. The metadata
contains relevant information to properly provision the data to the OS
file system, as well as update the system and add or remove additional
content to the OS.

The Manifests are mostly long lists of hashes that describe content.
Each bundle gets its own manifest file. There is a master manifest
file that describes all manifests to tie it all together.


## Fullfiles, packs, and delta packs

The data that an update provisions to a system can be obtained in
three different ways. There are three different methods, and they
exist to optimize the delivery of content and speed up updates.

Fullfiles are always generated for every file in every release. This
allows any Clear Linux OS to obtain the exact copy of the content
for each version directly. This would be used if the OS verification
(`swupd verify`) needed to replace a single file, for instance.

Packs are available for some releases and combine many files to speed
up the creation of installation media and large updates. Delta packs
are an optimized version of packs that only contain updates (binary
diffs) and cannot be used without having the original file content.

In most `swupd update` scenarios, the delta packs will be used as much
as possible, since they deliver the update content in the smallest
size possible.

In most `swupd bundle-add` scenarios, the packs will be used as
much as possible, since they deliver the needed content in a single
downloadable unit.


## Upstream

An Open Source Project is by definition "upstream". The Clear Linux OS
directly consumes project software from upstream as much as possible.
In most cases, this is trivial and the upstream community creates
proper source code releases, and addresses bugs and issues as needed
appropriately.

In some cases, the Clear Linux OS team maintains some projects as
an upstream project as well. Examples are obviously the mixer and
swupd projects.

The term upstream describes a relationship where content moves from
upstream to downstream in a fluid manner, and content is generally
aimed to be submitted back to upstream but receive significant review.
This concept applies also when people create a mixed Clear Linux OS
version. In that case, the official Clear Linux OS is the upstream
to the mixed version.


## Packages vs. projects

In the Clear Linux OS terminology, we separate the source code that
is in upstream repositories, and the distribution adaptation of the
products of that project.

The definition of a project is the thing that is the upstream of
a package. Projects are maintained by individual maintainers. The
Clear Linux OS team does not modify the project unless they are the
upstream maintainers. In the same way, people who are maintainers
of projects are directly providing content to the Clear Linux OS,
with all the responsibilities that go with it.

Packages describe how the project content is consumed. Many packages
have optional dependencies and configuration items that may or may not
be desired. On top of that, specifically targeted distributions like
Clear Linux OS may want to further patch the software to configure
the project to better work with the methods and rules that the Clear
Linux OS dictates.


## RPM

Internally, the Clear Linux OS uses the RPM package format to bridge
the software source code and the binary software update content. The
RPM format is an intermediate way of storing content.

Note: `swupd` does *not* use or recognize the RPM file format and the
`rpm` program on a Clear Linux OS installation is *not* capable of
using RPM files.

Within the build mechanisms that Clear Linux OS uses, the format
is used to store the output of the compilation process and provide
dependency relationships to the code that generates bundles. These
bundles rely on the RPMs dependencies, and by extension, the source
code dependency information. Using these dependencies, the mixer can
create meaningful bundles that contain the needed components to make
software functional without having to describe all dependencies in
the bundle definition.
