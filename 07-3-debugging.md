
How To Clear - Debugging applications in Clear Linux OS
=======================================================

## What you'll learn in this chapter

* Special debug file system concepts for Clear Linux OS
* Avoiding having to deploy your own fuse debug_fs


## Concepts

Developers need much more information about binaries, code and
functions when working with compiled code. Debuggers require lots of
meta information about source code line numbers, function parameters,
and memory offsets when developers need to debug applications.

Clear Linux OS features a unique solution that avoids the high cost
of providing full debug info files to all systems and creates an
on-the-fly virtual file system that only consumes network bandwidth
when applications are being debugged. This creates a work environment
that isn't in the way of developers but allows full debugging of
every application when needed.

The virtual debuginfo filesystem is implemented using FUSE fs,
and uses a HTTPS transport. Each Clear Linux OS installation mounts
this virtual network filesystem remotely, but no penalty is incurred
until debugging applications such as `gdb` need to access debug info
files. If a backtrace is needed or manual debugging is started,
the debugger will attempt to find the needed debug info files on
the virtual file system, and the required objects will be fetched
and cached.

Each binary that Clear Linux OS ships is tagged with a specific version
number unique to each compiled binary. This avoids conflicts between
the many different versions of a patched binary program. The Clear
Linux OS tooling generates the needed files on the server side with
each Clear Linux OS release.


## Don't strip custom binaries

Because the virtual debug file system will not contain any debug info
files about custom compiled or mixed binaries, people who need to debug
applications on the target should not strip their binaries. Otherwise
they will not be able to obtain debuginfo symbols. As an alternative,
you could also disable the virtual debug file system entirely and
ship custom debuginfo bundles.


## What else to try

* Launch gdb on a running application and obtain a backtrace.
* Compile a custom binary while disabling stripping using the autospec
`nostrip` option in `option.conf`.
