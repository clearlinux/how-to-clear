
How To Clear - Clear Linux Telemetry
====================================

## What you'll learn in this chapter

* Ground rules of telemetry, privacy, opt-in
* Basics of Clear Linux OS Telemetry
* Creating a custom telemetry event
* Backend collection concepts


## Concepts

Clear Linux OS uses a lightweight telemetry solution to allow 
applications to avoid being concerned with transporting the data and 
whether a user has opted in or out, and can be used to provide near 
real time data to improve applications.

Because software updates in Clear Linux OS are performed automatically, 
it is important that application developers leverage telemetry where 
appropriate. Traditional QA testing and functional testing are often 
incomplete. The Clear Linux OS telemetry solution bridges that gap and 
helps developers monitor their applications.

By default, telemetry isn't opt-out and the installer will ask people 
if telemetry should be enabled, with the default selection being "not 
enabled". We do however encourage people to enable telemetry to help 
out and make Clear Linux OS higher quality.

Intels privacy policies are applicable to the Clear Linux OS telemetry 
stack, and the Clear Linux OS telemetry does not collect intentionally 
identifyable information about the user or system owner. People who use 
the telemetry APIs discussed in this chapter should assure that this 
use also does not conflict with any of the policies or privacy laws.

The telemetry API revolves around the delivery of telemetry records as 
an individual unit to a HTTPS collection service. On the client, a 
spooling daemon `telemd` takes care of opt-in/out, throttling and 
encapsulating the telemetry data. Several telemetry probes generate 
probe specific payload data and deliver it to the `telemd` service for 
delivery.


## How to start

First, we'll need to enable telemetry on the target device. For this, 
we have to add the telemetrics bundle to our mix, and make it available 
to clients.

```
~/mix $ mixer bundle add telemetrics
Adding bundle "telemetrics" from upstream bundles
~/mix $ sudo mixer build all
```

We can obviously modify the image to add telemetry by default as a 
bundle, but we'd lose our existing system, so we'll just add it on our 
target device manually for now:

```
~ # swupd update
~ # swupd bundle-add telemetrics
```

Essentially, we now have everything to already create telemetry events, 
even from C programs or Python if needed, because the telemetry bundle 
provides a simple pipe-based cli program that can be called trivially:

```
~ # telem-record-gen --help
Usage:
  telem-record-gen [OPTIONS] - create and send a custom telemetry record

Help Options:
  -h, --help            Show help options

Application Options:
  -f, --config-file     Path to configuration file (not implemented yet)
  -V, --version         Print the program version
  -s, --severity        Severity level (1-4) - (default 1)
  -c, --class           Classification level_1/level_2/level_3
  -p, --payload         Record body (max size = 8k)
  -P, --payload-file    File to read payload from
  -R, --record-version  Version number for format of payload (default 1)
  -e, --event-id        Event id to use in the record
```

Using the C library (`libtelemetry.so` - `man 3 telemetry`) uses the 
exact same API parameters and yields the same effect.
 
Let's try generating a simple hearbeat event, similar to the `hprobe` 
hearbeat probe that Clear Linux OS includes by default.
 
```
~ # telem-record-gen -c org.clearlinux/hello/world -p "hello"
```

We won't see anything happen, but we can track existing and previous 
telemetry events with `telemctl`:

```
~ # telemctl journal
```

A full example of the hearbeat probe in C is documented in the source 
code here:

[https://github.com/clearlinux/telemetrics-client/blob/master/src/probes/hello.c]


## Pointing telemetry to a custom backend

If you have a custom collector functional, you can modify where your 
telemetry records get sent by modifying 
`/etc/telemetrics/telemetrics.conf` and changing the `server` value to 
point to the new telemetry collection URL. Setting up a custom 
collector is not covered in this training.

If you are deploying a custom backend for many Clear Linux OS 
installations, you may want to patch the system wide default 
`/usr/share/defaults/telemetrics/telemetrics.conf` file to include a 
custom collection URL built into the binary.


## Further reading

[https://clearlinux.org/features/telemetry]
[https://clearlinux.org/documentation/clear-linux/tutorials/telemetry-backend]
