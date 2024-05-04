
<div align="center">
    <img src="images/logo.png" width="280" />
</div>

## Overview

TayOS is a set of [Earthly](https://docs.earthly.dev) targets to build a very
basic busybox operating system. It was intended for me to learn more about
Linux build tools and the process of building real embedded Linux distributions
like Yocto and Alpine.

## Getting started

For a breakdown of the key steps, visit the
[blog post](https://makerforce.io/make-your-own-linux/) I wrote.

### Environment

First, install [Docker](https://docs.docker.com/install/) and
[Earthly](https://earthly.dev/get-earthly).

### Kernel

```sh
earthly +kernel
```

### Busybox

```sh
earthly +busybox
```

### OpenSSL

```sh
earthly +openssl
```

### Initial root filesystem

Take a look inside `rootfs/`. In there is the initalization script `init` that
is started after the kernel loads the initial root filesystem into memory. This
script sets up the required virtual filesystems for a working Linux system
(like `/dev`, `/proc`) and then starts the real PID 0 `init` daemon. The `init`
daemon then starts the script in `rootfs/etc/init.d/rcS` which sets up the
hostname and network interfaces.

The Earthly target will copy these files in together with Busybox and OpenSSL.

```sh
earthly +rootfs
```

You can check out the root filesystem by saving the artifacts:

```sh
earthly --artifact +rootfs/ ./output
```

### Direct kernel boot

To directly boot the kernel and initrd, save these files and run them in QEMU:

```sh
earthly --artifact '+kernel-and-initramfs/*'
qemu-system-x86_64 -machine q35 -m 512M -nic user -kernel vmlinuz -initrd initramfs -append 'console=ttyS0' -nographic
```

### ISO image

To combine the kernel and initrd into a bootable EFI ISO image, the GRUB
bootloader and xorrisofs tool can be used:

```sh
earthly --artifact +iso/tayos.iso
qemu-system-x86_64 -machine q35 -m 512M -nic user -boot d -cdrom tayos.iso -bios /usr/share/ovmf/bios.bin
```

## Customizing the kernel

```sh
earthly +kernel-menuconfig
```
