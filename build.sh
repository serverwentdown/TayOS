#!/bin/sh

set -e

export KERNEL_VERSION="linux-5.2.6"
export BUSYBOX_VERSION="busybox-1.31.0"

echo
echo ' _______           ____   _____ '
echo '|__   __|         / __ \ / ____|'
echo '   | | __ _ _   _| |  | | (___  '
echo '   | |/ _` | | | | |  | |\___ \ '
echo '   | | (_| | |_| | |__| |____) |'
echo '   |_|\__,_|\__, |\____/|_____/ '
echo '             __/ |              '
echo '            |___/               '
echo

echo
echo "Fetching dependencies..."
echo " + apk update"
apk update
echo " + apk add ..."
apk add \
    alpine-sdk \
    xz \
    ncurses-dev \
    bison \
    flex \
    bc \
    perl \
    elfutils-dev \
    openssl-dev \
    linux-headers \
    findutils

if [ -d $KERNEL_VERSION/ ]; then
    echo
    echo "Kernel already fetched. Skipping download"
else
    echo
    echo "Fetching $KERNEL_VERSION..."
    KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/$KERNEL_VERSION.tar.xz"
    echo " + wget $KERNEL_URL"
    wget $KERNEL_URL
    echo " + tar -xf $KERNEL_VERSION.tar.xz"
    tar -xf $KERNEL_VERSION.tar.xz
fi

if [ -d $BUSYBOX_VERSION/ ]; then
    echo
    echo "Busybox already fetched. Skipping download"
else
    echo
    echo "Fetching $BUSYBOX_VERSION..."
    BUSYBOX_URL="http://busybox.net/downloads/$BUSYBOX_VERSION.tar.bz2"
    echo " + wget $BUSYBOX_URL"
    wget $BUSYBOX_URL
    echo " + tar -xf $BUSYBOX_VERSION.tar.bz2"
    tar -xf $BUSYBOX_VERSION.tar.bz2
fi

echo
echo "All ready! I'm going to open a shell for you to start building the OS."
echo "Consult README.md for documentation."
echo " + sh"
sh
