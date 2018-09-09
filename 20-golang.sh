#!/bin/sh

set -e

GOLANG_VERSION=go1.11

echo
echo "Fetching dependencies..."
echo " + apk add ..."
apk add \
        bash \
        go

if [ -d go/ ]; then
    echo
    echo "Go source already fetched. Skipping download"
else
    echo
    echo "Fetching $GOLANG_VERSION..."
    GOLANG_URL="https://golang.org/dl/$GOLANG_VERSION.src.tar.gz"
    echo " + wget $GOLANG_URL"
    wget $GOLANG_URL
    echo " + tar -xf $GOLANG_VERSION.src.tar.gz"
    tar -xf $GOLANG_VERSION.src.tar.gz
fi

echo
echo " + cd go/src/"
cd go/src/

echo
echo "Building Go..."
echo " + export CGO_ENABLED=0"
export CGO_ENABLED=0
echo " + ./make.bash"
./make.bash

echo
echo " + cd ../../"
cd ../../

echo
echo "Cleaning up..."
echo " + rm -rf go/pkg/bootstrap/ go/pkg/obj"
rm -rf go/pkg/bootstrap/ go/pkg/obj

echo
echo "Copying into rootfs..."
echo " + mkdir -p rootfs/usr/local/go/"
mkdir -p rootfs/usr/local/go/
echo " + cp -R go/* rootfs/usr/local/go/"
cp -R go/* rootfs/usr/local/go/

echo
echo "Done!"
echo
