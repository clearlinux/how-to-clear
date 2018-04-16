
How To Clear
============

## Table of Contents

 1.  [Concepts](01-concepts.md)
 2.  [Extent of this training](02-scope.md)
 3.  [Basic Mixing](03-mixing.md)
 4.  [Deploying a Mix](04-deploying.md)
 5.  [Adding in custom RPMs](05-rpms.md)
 6.  Developer topics:
     1.  [Telemetry](06-1-telemetry.md)
     2.  [QA and testing](06-2-qa-testing.md)
     3.  [Debugging](06-3-debugging.md)

```
~ $ git clone https://github.com/clearlinux/how-to-clear
~ $ sudo swupd update
```

## Foreword

Clear Linux OS for Intel Architecture(*) was designed a long time ago 
to fill a major gap in the existing Linux OS ecosystem. The problem
identified was that Linux OS distributions either were of the type that
updated once or twice a year, or of the type that turned your system
into a dependency hell because it allowed your package management system
to combine incompatible components.

Clear Linux OS attempts to solve this problem by preventing you from 
combining fundamentally incompatible components, but allowing you to 
update with a frequency of several times a day, if needed. This allows 
users to receive smaller updates, but maintain functional software 
without the overhead of dealing with software incompatibilities.

Over the last few years we've made Clear Linux OS not only consistently 
deliver this in a usable form to users and attempted to use this as a 
vehicle to deliver much more technological advancement to users, but 
we've also worked to allow people to use the same tooling to do exactly 
the same, without recreating Clear Linux from scratch. Our tooling, 
concepts and content is modular and Free(as in beer and speech), and we 
have published everything.

The tooling covered in this training reproduces what the Clear Linux OS 
team works on and uses to create and maintain the OS, and allows users 
to create a derivative OS that is based on Clear Linux OS in various 
degrees of similarity. Either the derivative can be entirely new and 
use only the tooling provided, or the derivative can contain only minor 
changes.

The training revolves around mixer from start to finish, and makes 
several segues into more advanced topics that are relevant for the 
whole picture. In all details we end up showing in precise ways how the 
actual deployment of the results of the advanced topic can be pushed to 
actual target OS installations.

## About this document

This training document is a living training that will be adopted in the 
future to adjust for changes in the tooling and options, as well as any
needed fixes that need to be included.

The content itself is designed to be self-contained and allow someone 
to use a clean Clear Linux OS installation to do the training in its 
entirety. There should not be a need to install third party software, 
and the training material should explain all the concepts without the 
need for external reference documentation. It is expected however 
expected that people consult manual pages where appropriate.

Due to the nature of the Clear Linux OS tools, a functional network 
connection is required to use many of the tools. While it is possible 
to create a set of trainings that would function entirely offline, this 
would be time consuming and out of date almost immediately.

This training is hosted on github. We appreciate any feedback and 
comments, especially in the form of Pull Requests. Please visit the 
project page to open a ticket or clone/branch the training and help us.

    [how-to-clear](https://github.com/clearlinux/how-to-clear/)

For the convenience of students, we've included a folder called `files`
and added most of the files that will need to be created or downloaded
during the training exercises. This will allow students to skip through
some of the steps and get the proper files in place quickly and stay
focussed on the topic without spending time on meta-problems.

## Need Help?

The Clear Linux OS team can be reached for generic questions about 
Clear Linux OS, bugs, feedback and any relevant discussion if needed 
through several ways.

* [Mailinglist](https://lists.clearlinux.org/mailman/listinfo/dev)
* [IRC](http://webchat.freenode.net?channels=%23clearlinux)
* [Github](https://github.com/clearlinux/distribution)
