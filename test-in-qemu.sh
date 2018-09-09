#!/bin/sh

set -ex

qemu-system-x86_64 -m 512M \
    -machine pc-i440fx-2.11 \
    -kernel vmlinux \
    -initrd initramfs.img \
    -append 'console=ttyS0' \
    -nographic
