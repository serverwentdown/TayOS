#!/bin/sh

set -e

echo
echo " + cd $KERNEL_VERSION/"
cd $KERNEL_VERSION/

echo
read -p "Do you want to customize your kernel? (y/n) " -t 10 customize || customize=n
if [ "$customize" == "y" ]; then
    echo " + make menuconfig"
    make menuconfig
    
    echo
    echo "Backing up your configuration..."
    CONFIG_BACKUP="config-$(date +"%Y%m%d_%H%M%S")"
    echo " + cp .config $CONFIG_BACKUP"
    cp .config $CONFIG_BACKUP
else
    echo "Overwriting .config with a default configuration"
    echo " + make defconfig"
    make defconfig
fi 

echo
echo "Building kernel... This may take a while"
echo " + make -j$(nproc) all"
make -j$(nproc) all

echo
echo "Copying out kernel..."
SRC="arch/x86/boot/bzImage"
echo " + cp $SRC ../vmlinux"
cp $SRC ../vmlinux

echo
echo "Done!"
echo
