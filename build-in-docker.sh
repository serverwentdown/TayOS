#!/bin/sh

docker run --rm -it -v $PWD:/tayos --workdir /tayos alpine:3.10 ./build.sh
