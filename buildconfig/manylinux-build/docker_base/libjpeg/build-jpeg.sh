#!/bin/bash
set -e -x

cd $(dirname `readlink -f "$0"`)

JPEG=jpegsrc.v9d

curl -sL http://www.ijg.org/files/${JPEG}.tar.gz > ${JPEG}.tar.gz
sha512sum -c jpeg.sha512

tar xzf ${JPEG}.tar.gz
cd jpeg-*

./configure
make
make install

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Install to mac deps cache dir as well
    make install DESTDIR=${MACDEP_CACHE_PREFIX_PATH}
fi
