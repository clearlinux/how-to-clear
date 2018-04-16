#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
#  start_qemu.sh
#
#  Copyright (c) 2016-2017 Intel Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

if [ -z "$1" ]; then
    IMAGE=clear.img
else
    IMAGE="$1"
    shift
fi

if [[ "$IMAGE" =~ .xz$ ]]; then
    >&2 echo "File \"$IMAGE\" is still xz compressed. Uncompress it first with \"unxz\""
    exit 1
fi

if [ ! -f "$IMAGE" ]; then
    >&2 echo "Can't find image file \"$IMAGE\""
    exit 1
fi
rm -f debug.log

VMN=${VMN:=1}

qemu-system-x86_64 \
    -enable-kvm \
    -bios OVMF.fd \
    -smp sockets=1,cpus=4,cores=2 -cpu host \
    -m 1024 \
    -vga none -nographic \
    -drive file="$IMAGE",if=virtio,aio=threads,format=raw \
    -netdev user,id=mynet0,hostfwd=tcp::${VMN}0022-:22,hostfwd=tcp::${VMN}2375-:2375 \
    -device virtio-net-pci,netdev=mynet0 \
    -debugcon file:debug.log -global isa-debugcon.iobase=0x402 $@
