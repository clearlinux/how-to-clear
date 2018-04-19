
How To Clear - QA and testing Clear update content
==================================================

## What you'll learn in this chapter

* Build time tests concepts
* QA level testing tools


## Concepts

It is virtually impossible as a human being to continuously monitor
and test the proper functioning of a conglomerate as large as a normal
Linux\* distribution. For this reason, we need to automate testing
as much as possible and impose strict error checking at every level.

In Clear Linux OS, we have created several layers of testing that
will be Open Source in the future. At the time of writing this
document they are not Open Source, so this chapter is incomplete.

The automated package testing that comes with many of our packages
is available at this time.


## `make check`

Most upstream projects use the `check` framework to perform
package-level unit tests. Clear Linux OS and autospec attempt to use
these tests and enforce error checking, permitting a developer to
spot errors, pause release, and prevent a known error from reaching
customers. These errors are recorded and counted.

The `%check` section in a `spec` file is used to call the package
tests. If the output conforms to BAT or other standard unit testing
output that programs like `check` generate, these package test results
are recorded.

You can add custom check commands by creating a `make_check_command`
and inserting the custom tests or test command in there, and autospec
will include them in every subsequent run. The `options.conf` allows
you to either enforce that all tests must pass, or you may disable
that setting and allow failures.

The results of the tests are stored by the `common` tooling in the
`testresults` file. You should inspect this file after each build
to make sure that testing remains functional and no new errors are
introduced with each package change.

