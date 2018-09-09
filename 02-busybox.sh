#!/bin/sh

set -e

echo
echo " + cd $BUSYBOX_VERSION/"
cd $BUSYBOX_VERSION/

echo
read -p "Do you want to customize busybox? (y/n) " -t 10 customize
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
echo "Enabling static busybox..."
echo " + sed -ir 's/^(CONFIG_STATIC=.*|# CONFIG_STATIC is not set)/CONFIG_STATIC=y/' .config"
sed -i -r 's/^(CONFIG_STATIC=.*|# CONFIG_STATIC is not set)/CONFIG_STATIC=y/' .config

echo
echo "Building busybox... This may take a while"
echo " + make -j$(nproc) all"
make -j$(nproc) all

echo
echo "Generating a busybox filesystem..."
echo " + make install"
make install

echo
echo "Done!"
echo
