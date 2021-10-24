# This uses manylinux build scripts to build dependencies
#  on mac.
#
# Warning: this should probably not be run on your own mac.
#   Since it will install all these deps all over the place,
#   and they may conflict with existing installs you have.

set -e -x

export MACDEP_CACHE_PREFIX_PATH=${GITHUB_WORKSPACE}/pygame_mac_deps_${MAC_ARCH}

bash ./clean_usr_local.sh
mkdir $MACDEP_CACHE_PREFIX_PATH

# to use the gnu readlink, needs `brew install coreutils`
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# for great speed.
export MAKEFLAGS="-j 4"

if [[ "$MAC_ARCH" == "arm64" ]]; then
    # for scripts using ./configure to make arm64 binaries
    export CC="clang -target arm64-apple-macos11.0"
    export CXX="clang++ -target arm64-apple-macos11.0"

    # This does not do anything actually, but without this ./configure errors
    export ARCHS_CONFIG_FLAG="--host=aarch64-apple-macos20.0.0"
    
    export ARCHS_CONFIG_CMAKE_FLAG="-DCMAKE_OSX_ARCHITECTURES=arm64"

    # we don't need mac 10.9 support while compiling for apple M1 macs
    export MACOSX_DEPLOYMENT_TARGET=11.0
else
    export MACOSX_DEPLOYMENT_TARGET=10.9
fi

cd ../manylinux-build/docker_base

# Now start installing dependencies
# ---------------------------------

# sdl_image deps
bash zlib-ng/build-zlib-ng.sh
bash libpng/build-png.sh # depends on zlib
bash libjpegturbo/build-jpeg-turbo.sh
bash libtiff/build-tiff.sh
bash libwebp/build-webp.sh

# sdl_ttf deps
# export EXTRA_CONFIG_FREETYPE=--without-harfbuzz
# bash freetype/build-freetype.sh
# bash harfbuzz/build-harfbuzz.sh
# export EXTRA_CONFIG_FREETYPE=
bash freetype/build-freetype.sh

# sdl_mixer deps
bash libmodplug/build-libmodplug.sh
bash ogg/build-ogg.sh
bash flac/build-flac.sh

if [[ "$MAC_ARCH" != "arm64" ]]; then
    # temporarily skip building these on arm64 because of weird compile errors
    bash mpg123/build-mpg123.sh

    # fluidsynth (for sdl_mixer)
    bash gettext/build-gettext.sh
    bash glib/build-glib.sh # depends on gettext
    bash sndfile/build-sndfile.sh
    sudo mkdir -p /usr/local/lib64 # the install tries to put something in here
    sudo mkdir -p ${MACDEP_CACHE_PREFIX_PATH}/usr/local/lib64
    sudo bash fluidsynth/build-fluidsynth.sh # sudo otherwise install doesn't work.
fi

bash sdl_libs/build-sdl2-libs.sh

# for pygame.midi
bash portmidi/build-portmidi.sh
