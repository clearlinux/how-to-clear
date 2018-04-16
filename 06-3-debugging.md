
How To Clear - Debugging applications in Clear Linux OS
=======================================================

## What you'll learn in this chapter

* Clear Linux OS's special debug file system concepts
* Avoiding having to deploy your own fuse debug_fs


## Concepts

Developers need much more information about binaries, code and 
functions when working with compiled code. Debuggers require lots of 
meta information about source code line numbers, function parameters 
and memory offsets when developer need to debug applications.

Clear Linux OS features a unique solution that avoids the high cost of 
providing full debug info files to all systems and creates an 
on-the-fly virtual file system that only consumes network bandwidth 
when applications are being debugged. This creates a work environment 
that isn't in the way of developers but allows full debugging of every 
application in case this is needed.

The virtual debuginfo filesystem is implemented using FUSE fs, and uses 
a HTTPS transport. Each Clear Linux OS installation mounts this virtual 
network filesystem remotely, but until debugging applications like 
`gdb` need to access debug info files, no penalty is incurred. If a 
backtrace is needed or manual debugging is started, the debugger will 
attempt to find the needed debug info files on the virtual file system, 
and the required objects will be fetched and cached.

Each binary that Clear Linux OS ships is tagged with a specific version 
number unique to each compiled binary. This avoids conflicts between 
the many different versions of a patched binary program. The Clear 
Linux OS tooling generates the needed files on the serverside with each 
Clear Linux OS release.


## Don't strip custom binaries

Because the virtual debug file system will not contain any debug info 
files about custom compiled or mixed binaries, people who need to debug 
applications on the target should not strip their binaries. Otherwise 
they will not be able to obtain debuginfo symbols. As an alternative, 
one could also disable the virtual debug file system entirely and ship 
custom debuginfo bundles.


## What else to try

* Launch gdb on a running application and obtain a backtrace
* Compile a custom binary while disabling stripping using autospec's 
`nostrip` option in `option.conf`
