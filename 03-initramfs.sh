#!/bin/sh

set -e

echo 
echo "Setting up a inital RAM filesystem image..."

echo
echo "Generating the list of files to include..."
echo "Including files both from rootfs and busybox"
echo " + ./$KERNEL_VERSION/scripts/gen_initramfs_list.sh rootfs/ busybox/_install/ > initramfs.list"
./$KERNEL_VERSION/scripts/gen_initramfs_list.sh rootfs/ busybox/_install/ > initramfs.list

echo
echo "Generating the image..."
echo " + ./$KERNEL_VERSION/usr/gen_init_cpio initramfs.list > initramfs.img"
./$KERNEL_VERSION/usr/gen_init_cpio initramfs.list > initramfs.img

echo
echo "Done!"
echo
