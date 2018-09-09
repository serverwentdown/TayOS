#!/bin/sh

docker run --rm -it -v $PWD:/tayos --workdir /tayos alpine:3.8 ./build.sh
