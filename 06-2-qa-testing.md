
How To Clear - QA and testing Clear Update Content
==================================================

## What you'll learn in this chapter

* Build time tests concepts
* QA level testing tools


## Concepts

It is virtually impossible as a human being to continuously monitor
and test the proper functioning of a conglomerate as large as anormal
Linux distribution is. For this reason, we need to automate testing
as much as possible and impose strict error checking at every level.

In Clear Linux OS, we have created several layers of testing that
will be Open Source in the future, but at the time of writing this
document they are not, so this chapter is unfortunately incomplete.

What is available currently is the automated package testing that
comes with many of our packages.


## `make check`

Most upstream projects use the `check` framework to perform
package-level unit tests. Clear Linux OS and autospec attempt to use
these tests and enforce error checking, permitting a developer to
spot and pause release and prevent a preventable error from reaching
customers. These errors are recorded and counted.

The `%check` section in a `spec` file is used to call the package
tests.  If the output confirms to BAT or other standard unit testing
output that programs like `check` generate, these package test results
are recorded.

You can add custom check commands by creating an `make_check_command`
and inserting the custom tests or test command in there, and autospec
will include them in every subsequent run. The `options.conf` also
allows you to enforce that all tests must pass, or you may disable
that and allow failures.

The results of the tests are stored by the `common` tooling in the
`testresults` file. You should inspect this file after each build
to make sure that testing remains functional and no new errors are
introduced with each package change.

