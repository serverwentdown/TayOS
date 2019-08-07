#!/bin/sh

set -e

echo 
echo "Setting up a inital RAM filesystem image..."

echo
echo "Fixing permissions..."
echo " + chown -R 0:0 rootfs/"
chown -R 0:0 rootfs/

echo
echo "Generating the list of files to include..."
echo " + ./$KERNEL_VERSION/scripts/gen_initramfs_list.sh rootfs/ $BUSYBOX_VERSION/_install/ > initramfs.list"
./$KERNEL_VERSION/usr/gen_initramfs_list.sh rootfs/ $BUSYBOX_VERSION/_install/ > initramfs.list

echo
echo "Generating the image..."
echo " + ./$KERNEL_VERSION/usr/gen_init_cpio initramfs.list > initramfs.img"
./$KERNEL_VERSION/usr/gen_init_cpio initramfs.list > initramfs.img

echo
echo "Done!"
echo
